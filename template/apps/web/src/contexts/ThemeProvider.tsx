// Portal UI theming only. Proposal document theming uses a separate YAML system (see themes/*.yaml).

import { useEffect, type ReactNode } from "react";
import { useClientConfig } from "./ClientConfigProvider";

const CSS_VAR_MAP: Record<string, (b: { primaryColor: string; accentColor: string; fontFamily: string }) => string> = {
  "--color-primary": (b) => b.primaryColor,
  "--color-accent": (b) => b.accentColor,
  "--font-family": (b) => b.fontFamily,
};

export function ThemeProvider({ children }: { children: ReactNode }) {
  const { config } = useClientConfig();

  useEffect(() => {
    const root = document.documentElement;
    const branding = config.branding;

    for (const [varName, getter] of Object.entries(CSS_VAR_MAP)) {
      root.style.setProperty(varName, getter(branding));
    }

    root.style.setProperty("--color-background", "#ffffff");
  }, [config.branding]);

  return <>{children}</>;
}
