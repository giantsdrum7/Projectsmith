import "@testing-library/jest-dom/vitest";
import { cleanup } from "@testing-library/react";
import { afterEach, vi } from "vitest";

afterEach(() => {
  cleanup();
});

vi.mock("aws-amplify", () => ({
  Amplify: { configure: vi.fn() },
}));

vi.mock("aws-amplify/auth", () => ({
  getCurrentUser: vi.fn().mockRejectedValue(new Error("Not authenticated")),
  signIn: vi.fn(),
  signOut: vi.fn(),
  fetchAuthSession: vi.fn().mockResolvedValue({ tokens: null }),
}));
