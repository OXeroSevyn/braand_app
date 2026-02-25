"use client";

import { motion } from "framer-motion";
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
    { name: "Employees", icon: Users, href: "/dashboard/employees" },
    { name: "Notices", icon: Bell, href: "/dashboard/notices" },
    { name: "Messages", icon: MessageSquare, href: "/dashboard/messages", badge: 10 }
];

export function BottomNav() {
    const pathname = usePathname();

    return (
        <nav className="fixed bottom-0 left-0 right-0 h-16 bg-white/10 backdrop-blur-md border-t-2 border-black flex items-center justify-around z-50">
            {items.map((item) => {
                const isActive = pathname === item.href;
                return (
                    <Link
                        key={item.name}
                        href={item.href}
                        className="relative flex flex-col items-center gap-1 group"
                    >
                        <div className={cn(
                            "p-2 rounded-xl transition-all",
                            isActive ? "text-neon-green" : "text-white/40 group-hover:text-white"
                        )}>
                            <item.icon className="w-5 h-5" />
                            {item.badge && (
                                <span className="absolute top-0 right-0 bg-rose-500 text-white text-[8px] font-black w-4 h-4 rounded-full flex items-center justify-center border border-black translate-x-1 -translate-y-1">
                                    {item.badge}
                                </span>
                            )}
                        </div>
                        <span className={cn(
                            "text-[8px] font-black uppercase tracking-tighter transition-all",
                            isActive ? "text-neon-green" : "text-white/40 group-hover:text-white"
                        )}>
                            {item.name}
                        </span>
                        {isActive && (
                            <motion.div
                                layoutId="bottomNavActive"
                                className="absolute -bottom-2 w-1 h-1 bg-neon-green rounded-full"
                            />
                        )}
                    </Link>
                );
            })}
        </nav>
    );
}
