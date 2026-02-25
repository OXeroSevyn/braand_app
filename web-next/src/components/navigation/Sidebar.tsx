"use client";

import { motion } from "framer-motion";
import {
    LayoutDashboard,
    Users,
    FileBarChart,
    LogOut,
    Moon,
    Sun,
    Bell,
    Settings
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useAuth } from "@/context/AuthContext";
import { cn } from "@/lib/utils";

const navItems = [
    { name: "DASHBOARD", icon: LayoutDashboard, href: "/dashboard" },
    { name: "TEAM", icon: Users, href: "/dashboard/employees" },
    { name: "REPORTS", icon: FileBarChart, href: "/dashboard/reports" }
];

export function Sidebar() {
    const pathname = usePathname();
    const { user, signOut } = useAuth();

    return (
        <aside className="hidden lg:flex flex-col w-72 h-screen fixed left-0 top-0 bg-pure-black/50 border-r-2 border-black p-6 z-50">
            {/* Logo */}
            <div className="mb-12">
                <h1 className="text-2xl font-black tracking-tighter text-white uppercase italic">
                    BRAAND<span className="text-neon-green">INS.</span>
                </h1>
            </div>

            {/* Profile Card */}
            <div className="brutal-card p-4 mb-10 bg-dark-grey">
                <div className="flex items-center gap-4">
                    <div className="w-12 h-12 rounded-full border-4 border-neon-green bg-pure-black flex items-center justify-center text-xl font-black text-neon-green">
                        {user?.name?.charAt(0) || "S"}
                    </div>
                    <div>
                        <p className="text-sm font-black text-white uppercase">{user?.name || "User"}</p>
                        <p className="text-[10px] font-bold text-white/40 uppercase tracking-widest">{user?.role || "Admin"} • {user?.department || "Faculty"}</p>
                    </div>
                </div>
            </div>

            {/* Navigation */}
            <nav className="flex-1 space-y-4">
                {navItems.map((item) => {
                    const isActive = pathname === item.href;
                    return (
                        <Link
                            key={item.name}
                            href={item.href}
                            className={cn(
                                "flex items-center gap-4 p-4 font-black text-sm transition-all border-2 border-transparent",
                                isActive
                                    ? "bg-neon-green text-black border-black shadow-[4px_4px_0px_0px_rgba(0,0,0,1)]"
                                    : "text-white/40 hover:text-white hover:bg-white/5"
                            )}
                        >
                            <item.icon className="w-5 h-5" />
                            {item.name}
                        </Link>
                    );
                })}
            </nav>

            {/* Footer Actions */}
            <div className="space-y-4 pt-6 border-t border-white/5">
                <button className="flex items-center gap-4 p-4 w-full font-black text-sm text-white/40 hover:text-white transition-all">
                    <Moon className="w-5 h-5" />
                    DARK MODE
                </button>
                <button
                    onClick={() => signOut()}
                    className="flex items-center gap-4 p-4 w-full font-black text-sm text-rose-500 hover:text-rose-400 transition-all border-2 border-transparent hover:border-black hover:bg-rose-500/10"
                >
                    <LogOut className="w-5 h-5" />
                    LOGOUT
                </button>
            </div>
        </aside>
    );
}
