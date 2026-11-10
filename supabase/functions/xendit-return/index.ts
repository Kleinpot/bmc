Deno.serve(async (request: Request) => {
  const requestUrl = new URL(request.url);
  const externalId = requestUrl.searchParams.get("external_id") ?? "";
  const result = requestUrl.searchParams.get("result");

  if (request.method === "POST") {
    const callbackToken = request.headers.get("x-callback-token") ?? request.headers.get("X-CALLBACK-TOKEN");
    const expectedToken = Deno.env.get("XENDIT_WEBHOOK_TOKEN") ?? Deno.env.get("WEBHOOK_TOKEN");

    if (!callbackToken || !expectedToken || callbackToken !== expectedToken) {
      return new Response(JSON.stringify({ code: "UNAUTHORIZED", message: "Invalid callback token." }), {
        status: 401,
        headers: { "Content-Type": "application/json" },
      });
    }

    let payload: any = {};
    try {
      payload = await request.json();
    } catch {
      return new Response(JSON.stringify({ code: "BAD_REQUEST", message: "Invalid JSON payload." }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const eventType = payload?.event ?? payload?.type ?? "";
    const invoice = payload?.data ?? {};
    const paymentExternalId = String(invoice.external_id ?? "").trim();

    if (eventType === "invoice.paid" || eventType === "invoice.payment_failed") {
      // Xendit can send invoice events here. This endpoint just acknowledges the callback.
      // The app still verifies invoice status through xendit-payment.
      return new Response(JSON.stringify({ ok: true, event: eventType, external_id: paymentExternalId }), {
        status: 200,
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response(JSON.stringify({ ok: true, event: eventType ?? "unknown" }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  }

  const isValidExternalId = /^sillage-[A-Za-z0-9-]+$/.test(externalId);

  if (
    request.method !== "GET" ||
    !isValidExternalId ||
    (result !== "success" && result !== "failure")
  ) {
    return new Response("Invalid payment return link.", { status: 400 });
  }

  const returnUri = new URL("sillage://dashboard");
  returnUri.searchParams.set("external_id", externalId);
  returnUri.searchParams.set("result", result);
  const appLink = returnUri.toString();
  const appLinkAttribute = appLink.replaceAll("&", "&amp;").replaceAll('"', "&quot;");
  const appLinkScript = JSON.stringify(appLink).replaceAll("<", "\\u003c");
  const outcome = result === "success" ? "Payment submitted" : "Payment not completed";
  const html = `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Return to Sillage</title>
  </head>
  <body style="font-family: sans-serif; text-align: center; padding: 3rem 1rem;">
    <h1>${outcome}</h1>
    <p>Return to the Sillage app to verify your payment status.</p>
    <a href="${appLinkAttribute}">Return to app</a>
    <script>window.location.replace(${appLinkScript});</script>
  </body>
</html>`;
  return new Response(html, {
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": "no-store",
      "X-Content-Type-Options": "nosniff",
    },
  });
});
