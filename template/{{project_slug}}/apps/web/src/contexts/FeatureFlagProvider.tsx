import { createContext, useContext, type ReactNode } from "react";
import { useClientConfig, type FeatureFlags } from "./ClientConfigProvider";

const FeatureFlagContext = createContext<FeatureFlags | null>(null);

export function FeatureFlagProvider({ children }: { children: ReactNode }) {
  const { config } = useClientConfig();

  return (
    <FeatureFlagContext.Provider value={config.features}>
      {children}
    </FeatureFlagContext.Provider>
  );
}

export function useFeatureFlag(key: string): boolean {
  const flags = useContext(FeatureFlagContext);
  if (!flags) {
    throw new Error(
      "useFeatureFlag must be used within a FeatureFlagProvider",
    );
  }
  return flags[key] ?? false;
}

export function useFeatureFlags(): FeatureFlags {
  const flags = useContext(FeatureFlagContext);
  if (!flags) {
    throw new Error(
      "useFeatureFlags must be used within a FeatureFlagProvider",
    );
  }
  return flags;
}
