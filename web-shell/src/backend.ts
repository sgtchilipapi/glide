import type {
  GlideShellEnv,
  GlideSponsoredActionCompleteRequest,
  GlideSponsoredActionCompleteResponse,
  GlideSponsoredActionPrepareRequest,
  GlideSponsoredActionPrepareResponse,
} from "./types";

export function isBackendSponsoredActionPayload(
  payload: Record<string, unknown>,
): payload is GlideSponsoredActionPrepareRequest {
  return (
    payload.kind === "backend_sponsored_action" &&
    payload.chain === "solana" &&
    typeof payload.request_id === "string" &&
    typeof payload.wallet_address === "string" &&
    typeof payload.action === "object" &&
    payload.action !== null
  );
}

export async function prepareSponsoredAction(
  env: GlideShellEnv,
  payload: GlideSponsoredActionPrepareRequest,
): Promise<GlideSponsoredActionPrepareResponse> {
  const backendUrl = getBackendUrl(env);
  if (!backendUrl) {
    throw {
      code: "misconfigured",
      error: "Backend URL is blank. Sponsored actions require a configured backend_url.",
    };
  }

  const response = await fetch(joinBackendPath(backendUrl, "/api/sponsored-actions/prepare"), {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  const json = (await response.json()) as GlideSponsoredActionPrepareResponse;
  if (!response.ok) {
    throw {
      code: "backend_unavailable",
      error: getErrorMessage(json, `Backend prepare request failed with HTTP ${response.status}.`),
    };
  }
  if (!json.ok || json.status !== "prepared" || !json.transaction) {
    throw {
      code: "invalid_response",
      error: getErrorMessage(json, "Backend prepare response did not include a prepared transaction payload."),
    };
  }

  return json;
}

export async function completeSponsoredAction(
  env: GlideShellEnv,
  payload: GlideSponsoredActionCompleteRequest,
): Promise<GlideSponsoredActionCompleteResponse> {
  const backendUrl = getBackendUrl(env);
  if (!backendUrl) {
    throw {
      code: "misconfigured",
      error: "Backend URL is blank. Sponsored action completion requires a configured backend_url.",
    };
  }

  const response = await fetch(joinBackendPath(backendUrl, "/api/sponsored-actions/complete"), {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  });

  const json = (await response.json()) as GlideSponsoredActionCompleteResponse;
  if (!response.ok) {
    throw {
      code: "backend_unavailable",
      error: getErrorMessage(json, `Backend completion request failed with HTTP ${response.status}.`),
    };
  }
  if (!json.ok) {
    throw {
      code: "invalid_response",
      error: getErrorMessage(json, "Backend completion response did not indicate success."),
    };
  }

  return json;
}

function getBackendUrl(env: GlideShellEnv): string {
  return String(env.backend.url ?? "").trim();
}

function joinBackendPath(baseUrl: string, path: string): string {
  return `${baseUrl.replace(/\/+$/, "")}${path}`;
}

function getErrorMessage(
  response: { error?: { message?: string } } | null | undefined,
  fallback: string,
): string {
  return String(response?.error?.message ?? fallback);
}
