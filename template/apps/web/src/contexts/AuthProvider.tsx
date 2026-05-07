import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { Amplify } from "aws-amplify";
import {
  getCurrentUser,
  signIn as amplifySignIn,
  signOut as amplifySignOut,
  fetchAuthSession,
  type AuthUser,
} from "aws-amplify/auth";
import { getAuthConfig } from "@/lib/env";

interface AuthContextValue {
  isAuthenticated: boolean;
  isLoading: boolean;
  user: AuthUser | null;
  signIn: (username: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  getToken: () => Promise<string | null>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

const DEV_MOCK_USER: AuthUser = {
  userId: "dev-user-001",
  username: "dev@localhost",
};

function configureAmplify() {
  const config = getAuthConfig();
  if (!config.userPoolId || !config.userPoolClientId) return;

  Amplify.configure({
    Auth: {
      Cognito: {
        userPoolId: config.userPoolId,
        userPoolClientId: config.userPoolClientId,
      },
    },
  });
}

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const isDevMode = import.meta.env.VITE_AUTH_DEV_MODE === "true";

  useEffect(() => {
    if (isDevMode) {
      setUser(DEV_MOCK_USER);
      setIsLoading(false);
      return;
    }

    configureAmplify();

    getCurrentUser()
      .then(setUser)
      .catch(() => setUser(null))
      .finally(() => setIsLoading(false));
  }, [isDevMode]);

  const signIn = useCallback(
    async (username: string, password: string) => {
      if (isDevMode) {
        setUser(DEV_MOCK_USER);
        return;
      }
      await amplifySignIn({ username, password });
      const currentUser = await getCurrentUser();
      setUser(currentUser);
    },
    [isDevMode],
  );

  const signOut = useCallback(async () => {
    if (isDevMode) {
      setUser(null);
      return;
    }
    await amplifySignOut();
    setUser(null);
  }, [isDevMode]);

  const getToken = useCallback(async (): Promise<string | null> => {
    if (isDevMode) return "dev-mock-token";
    try {
      const session = await fetchAuthSession();
      return session.tokens?.idToken?.toString() ?? null;
    } catch {
      return null;
    }
  }, [isDevMode]);

  const value = useMemo<AuthContextValue>(
    () => ({
      isAuthenticated: user !== null,
      isLoading,
      user,
      signIn,
      signOut,
      getToken,
    }),
    [user, isLoading, signIn, signOut, getToken],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
