import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { QueryClientProvider, QueryClient } from "@tanstack/react-query";
import { AuthProvider } from "@/contexts/AuthProvider";
import {
  ClientConfigProvider,
  useClientConfig,
} from "@/contexts/ClientConfigProvider";
import { ThemeProvider } from "@/contexts/ThemeProvider";
import { FeatureFlagProvider } from "@/contexts/FeatureFlagProvider";
import { PortalLayout } from "@/components/PortalLayout";
import * as fs from "node:fs";
import * as path from "node:path";

const MOCK_CONFIG = {
  branding: {
    appName: "Test Portal",
    logoUrl: "/logo.svg",
    primaryColor: "#2563eb",
    accentColor: "#f59e0b",
    fontFamily: "Inter, system-ui, sans-serif",
    heroTitle: "Welcome",
    heroSubtitle: "Test subtitle",
  },
  features: {
    proposalGen: true,
    chat: true,
    documents: false,
    rateCases: false,
  },
  navigation: [
    { label: "Dashboard", path: "/portal", icon: "layout-dashboard", featureKey: null },
    { label: "Proposals", path: "/portal/proposals", icon: "file-text", featureKey: "proposalGen" },
    { label: "Chat", path: "/portal/chat", icon: "message-circle", featureKey: "chat" },
    { label: "Documents", path: "/portal/documents", icon: "folder", featureKey: "documents" },
  ],
};

function createTestQueryClient() {
  return new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
}

function TestProviders({ children }: { children: React.ReactNode }) {
  const queryClient = createTestQueryClient();
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <ClientConfigProvider>
          <ThemeProvider>
            <FeatureFlagProvider>{children}</FeatureFlagProvider>
          </ThemeProvider>
        </ClientConfigProvider>
      </AuthProvider>
    </QueryClientProvider>
  );
}

function mockFetchConfig() {
  vi.spyOn(globalThis, "fetch").mockResolvedValue(
    new Response(JSON.stringify(MOCK_CONFIG), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    }),
  );
}

describe("PortalLayout renders", () => {
  beforeEach(() => {
    import.meta.env.VITE_AUTH_DEV_MODE = "true";
    mockFetchConfig();
  });

  it("renders sidebar navigation and content area", async () => {
    render(
      <TestProviders>
        <PortalLayout>
          <div data-testid="content">Page content</div>
        </PortalLayout>
      </TestProviders>,
    );

    await waitFor(() => {
      expect(screen.getByRole("navigation", { name: /main navigation/i })).toBeInTheDocument();
    });

    expect(screen.getByTestId("content")).toBeInTheDocument();
  });

  it("filters nav items by feature flags", async () => {
    render(
      <TestProviders>
        <PortalLayout>
          <div>Content</div>
        </PortalLayout>
      </TestProviders>,
    );

    await waitFor(() => {
      expect(screen.getByText("Dashboard")).toBeInTheDocument();
    });

    expect(screen.getByText("Proposals")).toBeInTheDocument();
    expect(screen.getByText("Chat")).toBeInTheDocument();
    expect(screen.queryByText("Documents")).not.toBeInTheDocument();
  });
});

describe("Config loads and provides flags", () => {
  beforeEach(() => {
    import.meta.env.VITE_AUTH_DEV_MODE = "true";
    mockFetchConfig();
  });

  it("fetches client-config.json and exposes branding and flags", async () => {
    function ConfigConsumer() {
      const { config } = useClientConfig();
      return (
        <div>
          <span data-testid="app-name">{config.branding.appName}</span>
          <span data-testid="proposal-flag">
            {config.features.proposalGen ? "on" : "off"}
          </span>
          <span data-testid="ratecases-flag">
            {config.features.rateCases ? "on" : "off"}
          </span>
        </div>
      );
    }

    render(
      <TestProviders>
        <ConfigConsumer />
      </TestProviders>,
    );

    await waitFor(() => {
      expect(screen.getByTestId("app-name")).toHaveTextContent("Test Portal");
    });
    expect(screen.getByTestId("proposal-flag")).toHaveTextContent("on");
    expect(screen.getByTestId("ratecases-flag")).toHaveTextContent("off");
  });
});

describe("Generated types", () => {
  it("schema files exist in generated directory after type generation", () => {
    const generatedDir = path.resolve(__dirname, "../types/generated");
    const exists = fs.existsSync(generatedDir);
    expect(exists).toBe(true);

    const files = fs.readdirSync(generatedDir);
    const schemaFiles = files.filter(
      (f: string) => f.endsWith(".schema.json") || f.endsWith(".d.ts"),
    );
    expect(schemaFiles.length).toBeGreaterThan(0);
  });
});
