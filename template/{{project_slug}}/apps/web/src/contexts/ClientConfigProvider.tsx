import {
  createContext,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from "react";
import { getConfigUrl } from "@/lib/env";

export interface BrandConfig {
  appName: string;
  logoUrl: string;
  primaryColor: string;
  accentColor: string;
  fontFamily: string;
  heroTitle: string;
  heroSubtitle: string;
}

export interface FeatureFlags {
  proposalGen: boolean;
  chat: boolean;
  documents: boolean;
  rateCases: boolean;
  [key: string]: boolean;
}

export interface NavItem {
  label: string;
  path: string;
  icon: string;
  featureKey: string | null;
}

export interface ClientConfig {
  branding: BrandConfig;
  features: FeatureFlags;
  navigation: NavItem[];
}

const DEFAULT_CONFIG: ClientConfig = {
  branding: {
    appName: "Portal",
    logoUrl: "/assets/logo.svg",
    primaryColor: "#2563eb",
    accentColor: "#f59e0b",
    fontFamily: "Inter, system-ui, sans-serif",
    heroTitle: "Welcome",
    heroSubtitle: "AI-powered consulting tools",
  },
  features: {
    proposalGen: false,
    chat: false,
    documents: false,
    rateCases: false,
  },
  navigation: [
    { label: "Dashboard", path: "/portal", icon: "layout-dashboard", featureKey: null },
  ],
};

interface ClientConfigContextValue {
  config: ClientConfig;
  isLoading: boolean;
  error: string | null;
}

const ClientConfigContext = createContext<ClientConfigContextValue | null>(null);

async function fetchConfig(): Promise<ClientConfig> {
  const configUrl = getConfigUrl();
  const urls = configUrl
    ? [configUrl]
    : ["/client-config.json", "/client-config.example.json"];

  for (const url of urls) {
    try {
      const response = await fetch(url);
      if (response.ok) {
        return (await response.json()) as ClientConfig;
      }
    } catch {
      // Try next URL
    }
  }

  console.warn(
    "ClientConfigProvider: failed to load config from all sources, using defaults",
  );
  return DEFAULT_CONFIG;
}

export function ClientConfigProvider({ children }: { children: ReactNode }) {
  const [config, setConfig] = useState<ClientConfig>(DEFAULT_CONFIG);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    fetchConfig()
      .then((loaded) => {
        if (!cancelled) setConfig(loaded);
      })
      .catch((err: unknown) => {
        if (!cancelled) {
          const message = err instanceof Error ? err.message : "Unknown error";
          console.warn("ClientConfigProvider: fetch error —", message);
          setError(message);
        }
      })
      .finally(() => {
        if (!cancelled) setIsLoading(false);
      });

    return () => {
      cancelled = true;
    };
  }, []);

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gray-50">
        <div className="text-sm text-gray-500">Loading configuration…</div>
      </div>
    );
  }

  const contextValue: ClientConfigContextValue = { config, isLoading, error };

  return (
    <ClientConfigContext.Provider value={contextValue}>
      {children}
    </ClientConfigContext.Provider>
  );
}

export function useClientConfig(): ClientConfigContextValue {
  const context = useContext(ClientConfigContext);
  if (!context) {
    throw new Error(
      "useClientConfig must be used within a ClientConfigProvider",
    );
  }
  return context;
}
