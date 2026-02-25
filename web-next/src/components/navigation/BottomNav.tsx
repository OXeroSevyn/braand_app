"use client";

import {
    LayoutDashboard,
    Calendar,
    FileBarChart,
    CheckSquare,
    Users,
    Bell,
    MessageSquare
} from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";

const items = [
    { name: "Dashboard", icon: LayoutDashboard, href: "/dashboard" },
    { name: "Attendance", icon: Calendar, href: "/dashboard/attendance" },
    { name: "Reports", icon: FileBarChart, href: "/dashboard/reports" },
    { name: "Tasks", icon: CheckSquare, href: "/dashboard/tasks" },
    { name: "Team", icon: Users, href: "/dashboard/employees" },
    { name: "Notices", icon: Bell, href: "/dashboard/notices" },
    { name: "Inbox", icon: MessageSquare, href: "/dashboard/messages", badge: 10 }
];

export function BottomNav() {
    const pathname = usePathname();

    return (
        <nav className="fixed bottom-0 left-0 right-0 h-20 bg-surface-container border-t border-white/5 flex items-center justify-around px-2 z-50 lg:hidden shadow-m3-2">
            {items.map((item) => {
                const isActive = pathname === item.href;
                return (
                    <Link
                        key={item.name}
                        href={item.href}
                        className="relative flex flex-col items-center gap-1 flex-1 py-3 group"
                    >
                        {/* M3 Active Indicator Pill */}
                        <div className="relative">
                            <div className={cn(
                                "absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-16 h-8 rounded-full transition-all duration-300 transform",
                                isActive ? "bg-primary scale-100 opacity-100" : "bg-primary scale-50 opacity-0 group-hover:opacity-10"
                            )} />

                            <div className={cn(
                                "relative z-10 p-1 flex items-center justify-center transition-colors duration-200",
                                isActive ? "text-on-primary" : "text-on-surface-variant group-hover:text-white"
                            )}>
                                <item.icon className="w-6 h-6" />
                                {item.badge && (
                                    <span className="absolute -top-1 -right-1 bg-rose-500 text-white text-[9px] font-bold w-4 h-4 rounded-full flex items-center justify-center border-2 border-surface-container">
                                        {item.badge}
                                    </span>
                                )}
                            </div>
                        </div>

                        <span className={cn(
                            "text-[10px] font-bold transition-all duration-200 mt-1",
                            isActive ? "text-white" : "text-on-surface-variant group-hover:text-white"
                        )}>
                            {item.name}
                        </span>
                    </Link>
                );
            })}
        </nav>
    );
}
