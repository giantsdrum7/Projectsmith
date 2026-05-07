interface AuthConfig {
  userPoolId: string;
  userPoolClientId: string;
  identityPoolId?: string;
  region: string;
}

export function getApiBaseUrl(): string {
  return import.meta.env.VITE_API_BASE_URL ?? "/api";
}

export function getAuthConfig(): AuthConfig {
  return {
    userPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID ?? "",
    userPoolClientId: import.meta.env.VITE_COGNITO_CLIENT_ID ?? "",
    identityPoolId: import.meta.env.VITE_COGNITO_IDENTITY_POOL_ID,
    region: import.meta.env.VITE_AWS_REGION ?? "us-east-1",
  };
}

export function getConfigUrl(): string | undefined {
  return import.meta.env.VITE_CLIENT_CONFIG_URL;
}
