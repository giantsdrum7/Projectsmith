import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { QueryClientProvider } from "@tanstack/react-query";
import { queryClient } from "@/lib/queryClient";
import { AuthProvider } from "@/contexts/AuthProvider";
import { ClientConfigProvider } from "@/contexts/ClientConfigProvider";
import { ThemeProvider } from "@/contexts/ThemeProvider";
import { App } from "@/App";
import "@/index.css";

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <ClientConfigProvider>
          <ThemeProvider>
            <App />
          </ThemeProvider>
        </ClientConfigProvider>
      </AuthProvider>
    </QueryClientProvider>
  </StrictMode>,
);
