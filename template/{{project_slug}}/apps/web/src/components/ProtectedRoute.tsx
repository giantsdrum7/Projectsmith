import { type ReactNode } from "react";
import { Redirect, useLocation } from "wouter";
import { useAuth } from "@/contexts/AuthProvider";

export function ProtectedRoute({ children }: { children: ReactNode }) {
  const { isAuthenticated, isLoading } = useAuth();
  const [location] = useLocation();

  if (isLoading) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-gray-50">
        <div className="text-sm text-gray-500">Authenticating…</div>
      </div>
    );
  }

  if (!isAuthenticated) {
    const returnTo = encodeURIComponent(location);
    return <Redirect to={`/signin?returnTo=${returnTo}`} />;
  }

  return <>{children}</>;
}
