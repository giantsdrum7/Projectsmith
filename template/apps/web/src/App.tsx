import { Route, Switch, Redirect } from "wouter";
import { ProtectedRoute } from "@/components/ProtectedRoute";
import { PortalLayout } from "@/components/PortalLayout";
import { FeatureFlagProvider } from "@/contexts/FeatureFlagProvider";

function SignIn() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-gray-50">
      <div className="w-full max-w-sm rounded-lg border bg-white p-8 shadow-sm">
        <h1 className="mb-6 text-center text-2xl font-semibold">Sign In</h1>
        <p className="text-center text-sm text-gray-500">
          {/* TODO: Add Amplify Authenticator or custom sign-in form post-generation */}
          Authentication form placeholder
        </p>
      </div>
    </main>
  );
}

function NotFound() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-gray-50">
      <div className="text-center">
        <h1 className="text-4xl font-bold text-gray-900">404</h1>
        <p className="mt-2 text-gray-500">Page not found</p>
        <a href="/portal" className="mt-4 inline-block text-sm text-primary underline">
          Return to portal
        </a>
      </div>
    </main>
  );
}

function PortalHome() {
  return (
    <div className="p-6">
      <h2 className="text-xl font-semibold text-gray-900">Dashboard</h2>
      <p className="mt-2 text-sm text-gray-500">
        {/* TODO: Add product-specific routes post-generation */}
        Welcome to the portal. Add page content after project generation.
      </p>
    </div>
  );
}

export function App() {
  return (
    <FeatureFlagProvider>
      <Switch>
        <Route path="/">
          <Redirect to="/portal" />
        </Route>

        <Route path="/signin" component={SignIn} />

        <Route path="/portal/:rest*">
          <ProtectedRoute>
            <PortalLayout>
              <PortalHome />
            </PortalLayout>
          </ProtectedRoute>
        </Route>

        <Route component={NotFound} />
      </Switch>
    </FeatureFlagProvider>
  );
}
