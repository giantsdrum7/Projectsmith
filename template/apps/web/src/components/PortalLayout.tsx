import { useState, type ReactNode } from "react";
import { useLocation } from "wouter";
import { cn } from "@/lib/utils";
import { useClientConfig, type NavItem } from "@/contexts/ClientConfigProvider";
import { useFeatureFlags } from "@/contexts/FeatureFlagProvider";
import { useAuth } from "@/contexts/AuthProvider";

function NavIcon({ name }: { name: string }) {
  const icons: Record<string, string> = {
    "layout-dashboard": "▦",
    "file-text": "📄",
    "message-circle": "💬",
    folder: "📁",
    calculator: "🔢",
  };
  return <span aria-hidden="true">{icons[name] ?? "•"}</span>;
}

function SidebarLink({
  item,
  isActive,
  collapsed,
}: {
  item: NavItem;
  isActive: boolean;
  collapsed: boolean;
}) {
  return (
    <a
      href={item.path}
      className={cn(
        "flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors",
        isActive
          ? "bg-primary/10 text-primary"
          : "text-gray-600 hover:bg-gray-100 hover:text-gray-900",
      )}
      aria-current={isActive ? "page" : undefined}
    >
      <NavIcon name={item.icon} />
      {!collapsed && <span>{item.label}</span>}
    </a>
  );
}

export function PortalLayout({ children }: { children: ReactNode }) {
  const [collapsed, setCollapsed] = useState(false);
  const [location] = useLocation();
  const { config } = useClientConfig();
  const features = useFeatureFlags();
  const { user, signOut } = useAuth();

  const visibleNav = config.navigation.filter(
    (item) => item.featureKey === null || features[item.featureKey],
  );

  return (
    <div className="flex min-h-screen bg-gray-50">
      {/* Sidebar */}
      <aside
        className={cn(
          "flex flex-col border-r bg-white transition-all duration-200",
          collapsed ? "w-16" : "w-64",
        )}
        role="navigation"
        aria-label="Main navigation"
      >
        {/* Sidebar header */}
        <div className="flex h-14 items-center justify-between border-b px-4">
          {!collapsed && (
            <span className="truncate text-sm font-semibold">
              {config.branding.appName}
            </span>
          )}
          <button
            onClick={() => setCollapsed((prev) => !prev)}
            className="rounded p-1 text-gray-400 hover:bg-gray-100 hover:text-gray-600"
            aria-label={collapsed ? "Expand sidebar" : "Collapse sidebar"}
          >
            {collapsed ? "→" : "←"}
          </button>
        </div>

        {/* Nav items */}
        <nav className="flex-1 space-y-1 p-2">
          {visibleNav.map((item) => (
            <SidebarLink
              key={item.path}
              item={item}
              isActive={location === item.path || location.startsWith(item.path + "/")}
              collapsed={collapsed}
            />
          ))}
        </nav>

        {/* User section */}
        <div className="border-t p-3">
          {!collapsed && user && (
            <div className="mb-2 truncate text-xs text-gray-500">
              {user.username}
            </div>
          )}
          <button
            onClick={() => void signOut()}
            className="w-full rounded px-3 py-1.5 text-left text-xs text-gray-500 hover:bg-gray-100 hover:text-gray-700"
            aria-label="Sign out"
          >
            {collapsed ? "⎋" : "Sign out"}
          </button>
        </div>
      </aside>

      {/* Main area */}
      <div className="flex flex-1 flex-col">
        {/* Header */}
        <header className="flex h-14 items-center justify-between border-b bg-white px-6">
          <div className="text-sm text-gray-500">
            {/* TODO: Add breadcrumbs post-generation */}
          </div>
          <div className="text-sm font-medium text-gray-700">
            {config.branding.appName}
          </div>
        </header>

        {/* Content */}
        <main className="flex-1">{children}</main>
      </div>
    </div>
  );
}
