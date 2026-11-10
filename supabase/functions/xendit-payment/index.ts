import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const XENDIT_API_BASE = "https://api.xendit.co";

function getEnv(name: string, fallbackName?: string) {
  return Deno.env.get(name) ?? (fallbackName ? Deno.env.get(fallbackName) : undefined);
}

function buildXenditAuthHeader(secretKey: string) {
  return `Basic ${btoa(`${secretKey}:`)}`;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json().catch(() => ({}));
    const action = String(body?.action ?? "create");

    const xenditSecretKey = getEnv("XENDIT_SECRET_KEY", "WEBHOOK_SECRET_KEY");
    if (!xenditSecretKey) {
      throw new Error("Xendit secret key is not configured in Supabase Secrets.");
    }

    const authHeader = buildXenditAuthHeader(xenditSecretKey);

    if (action === "status") {
      const externalId = String(body?.external_id ?? "").trim();
      if (!externalId) {
        throw new Error("Missing external_id for status lookup.");
      }

      const statusUrl = `${XENDIT_API_BASE}/v2/invoices?external_id=${encodeURIComponent(externalId)}`;
      const statusResponse = await fetch(statusUrl, {
        method: "GET",
        headers: {
          Authorization: authHeader,
          "Content-Type": "application/json",
        },
      });

      const statusText = await statusResponse.text();
      let statusResult: any;
      try {
        statusResult = JSON.parse(statusText);
      } catch {
        throw new Error(`Xendit returned non-JSON: ${statusText}`);
      }

      if (!statusResponse.ok) {
        throw new Error(statusResult.message || statusResult.error_code || "Xendit API rejection.");
      }

      const invoiceArray = Array.isArray(statusResult)
        ? statusResult
        : Array.isArray(statusResult.data)
          ? statusResult.data
          : [];

      const invoice =
        invoiceArray.find((entry: any) => String(entry.external_id ?? "") === externalId) ??
        invoiceArray[0] ??
        null;

      if (!invoice) {
        return new Response(JSON.stringify({
          external_id: externalId,
          status: "NOT_FOUND",
          amount: 0,
        }), {
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        });
      }

      return new Response(JSON.stringify({
        external_id: invoice.external_id ?? externalId,
        status: String(invoice.status ?? "UNKNOWN").toUpperCase(),
        amount: Number(invoice.amount ?? 0),
        invoice_url: invoice.invoice_url ?? null,
      }), {
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (action !== "create") {
      throw new Error(`Unsupported Xendit action: ${action}`);
    }

    const { items, delivery, gift_wrap, payer_name, payer_phone } = body;
    let payer_email = String(body?.payer_email ?? "").trim();
    
    // Fallback email kung walang ibinigay o invalid ang format para iwasan ang Xendit rejection
    if (!payer_email || !payer_email.includes("@")) {
      payer_email = "customer@example.com";
    }

    if (!items || !Array.isArray(items) || items.length === 0) {
      throw new Error("A checkout product has invalid pricing.");
    }

    const formattedItems = items.map((item: any) => {
      let rawPrice = item.price ?? item.amount ?? item.unit_price;
      if (typeof rawPrice === "string") {
        rawPrice = rawPrice.replace(/[^\d.]/g, "");
      }
      const parsedPrice = Math.round(Number(rawPrice));

      if (Number.isNaN(parsedPrice) || parsedPrice <= 0) {
        throw new Error("A checkout product has invalid pricing.");
      }

      return {
        name: item.name ?? item.title ?? "Product",
        price: parsedPrice,
        quantity: Number(item.quantity ?? 1),
      };
    });

    const subtotal = formattedItems.reduce(
      (acc: number, item: any) => acc + item.price * item.quantity,
      0,
    );
    const shippingFee = delivery === "Express" ? 25 : subtotal >= 3500 ? 0 : 12;
    const giftWrapFee = gift_wrap ? 8 : 0;
    const totalAmount = Number(body?.amount ?? subtotal + shippingFee + giftWrapFee);

    if (!Number.isFinite(totalAmount) || totalAmount <= 0) {
      throw new Error("A checkout product has invalid pricing.");
    }

    const externalId = `sillage-${Date.now()}-${crypto.randomUUID()}`;
    const functionOrigin = new URL(req.url).origin;
    const returnBase = new URL("/functions/v1/xendit-return", functionOrigin).toString();
    const redirectParams = `external_id=${encodeURIComponent(externalId)}`;

    const xenditResponse = await fetch(`${XENDIT_API_BASE}/v2/invoices`, {
      method: "POST",
      headers: {
        Authorization: authHeader,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        external_id: externalId,
        amount: Math.round(totalAmount),
        currency: "PHP",
        description: "Payment for order via Sillage App",
        items: formattedItems,
        success_redirect_url: `${returnBase}?${redirectParams}&result=success`,
        failure_redirect_url: `${returnBase}?${redirectParams}&result=failure`,
        customer: {
          given_names: String(payer_name ?? "Customer").trim() || "Customer",
          email: payer_email,
          mobile_number: String(payer_phone ?? "").trim() || undefined,
        },
      }),
    });

    const responseText = await xenditResponse.text();
    let xenditResult: any;
    try {
      xenditResult = JSON.parse(responseText);
    } catch {
      throw new Error(`Xendit returned non-JSON: ${responseText}`);
    }

    if (!xenditResponse.ok) {
      throw new Error(xenditResult.message || xenditResult.error_code || "Xendit API rejection.");
    }

    if (!xenditResult.invoice_url) {
      throw new Error("Xendit did not return an invoice URL.");
    }

    return new Response(JSON.stringify({
      invoice_url: xenditResult.invoice_url,
      external_id: xenditResult.external_id ?? externalId,
      amount: Number(xenditResult.amount ?? totalAmount),
      status: String(xenditResult.status ?? "PENDING").toUpperCase(),
    }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});