import { corsHeaders } from "./cors.ts";

export function jsonResponse(
  status: number,
  body: Record<string, unknown>,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function errorResponse(
  status: number,
  message: string,
  code = "REQUEST_FAILED",
  extra: Record<string, unknown> = {},
): Response {
  return jsonResponse(status, { message, code, ...extra });
}
