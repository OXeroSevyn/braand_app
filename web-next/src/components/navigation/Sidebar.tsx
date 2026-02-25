"use client";

import {
    LayoutDashboard,
    Users,
    FileBarChart,
    LogOut,
    Clock
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "@/context/AuthContext";
import { cn } from "@/lib/utils";

const navItems = [
    { name: "Dashboard", icon: LayoutDashboard, href: "/dashboard" },
    { name: "Attendance", icon: Clock, href: "/dashboard/attendance" },
    { name: "Team", icon: Users, href: "/dashboard/employees" },
    { name: "Reports", icon: FileBarChart, href: "/dashboard/reports" }
];

export function Sidebar() {
    const pathname = usePathname();
    const { user, signOut } = useAuth();

    return (
        <aside className="hidden lg:flex flex-col w-[300px] h-[calc(100vh-2rem)] fixed left-4 top-4 bg-surface-container rounded-[28px] p-4 z-50 shadow-m3-1 border border-white/5">
            {/* Header / Logo */}
            <div className="mb-8 px-4 pt-4">
                <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center">
                        <div className="w-4 h-4 rounded-sm bg-on-primary rotate-45" />
                    </div>
                    <h1 className="text-xl font-bold tracking-tight text-white uppercase italic">
                        BRAAND<span className="text-primary italic">.</span>
                    </h1>
                </div>
            </div>

            {/* Navigation Drawer Items */}
            <nav className="flex-1 space-y-1">
                {navItems.map((item) => {
                    const isActive = pathname === item.href;
                    return (
                        <Link
                            key={item.name}
                            href={item.href}
                            className={cn(
                                "group relative flex items-center gap-3 px-4 py-3 h-14 rounded-full transition-all overflow-hidden",
                                isActive
                                    ? "text-on-primary font-bold"
                                    : "text-on-surface-variant hover:bg-white/5"
                            )}
                        >
                            {/* Active Indicator Pill */}
                            {isActive && (
                                <div className="absolute inset-0 bg-primary z-0" />
                            )}

                            <div className="relative z-10 flex items-center gap-3">
                                <item.icon className={cn("w-5 h-5", isActive ? "text-on-primary" : "text-on-surface-variant")} />
                                <span className="text-sm tracking-wide">{item.name}</span>
                            </div>
                        </Link>
                    );
                })}
            </nav>

            {/* Profile & Footer Action */}
            <div className="mt-auto space-y-4 pt-4 px-2">
                <div className="flex items-center gap-3 p-3 rounded-2xl bg-surface-variant/50">
                    <div className="w-10 h-10 rounded-full bg-primary/20 border border-primary/20 flex items-center justify-center text-primary font-bold">
                        {user?.name?.charAt(0) || "U"}
                    </div>
                    <div className="flex-1 overflow-hidden">
                        <p className="text-xs font-bold text-white truncate">{user?.name || "User"}</p>
                        <p className="text-[10px] text-on-surface-variant uppercase tracking-tighter">{user?.role || "Admin"}</p>
                    </div>
                </div>

                <button
                    onClick={() => signOut()}
                    className="flex items-center gap-3 w-full px-4 py-3 h-12 rounded-full text-on-surface-variant hover:bg-rose-500/10 hover:text-rose-400 transition-all group"
                >
                    <LogOut className="w-5 h-5 opacity-50 group-hover:opacity-100" />
                    <span className="text-sm font-medium uppercase tracking-widest">Logout</span>
                </button>
            </div>
        </aside>
    );
}

