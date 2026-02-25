"use client";

import { GlassCard } from "@/components/ui/GlassCard";
import { Bell, Info, AlertTriangle } from "lucide-react";

export default function NoticesPage() {
    return (
        <div className="min-h-screen p-6 lg:p-10">
            <header className="mb-12">
                <h1 className="text-4xl md:text-5xl font-black tracking-tighter uppercase text-white">
                    NOTICES
                </h1>
                <p className="text-[10px] font-bold text-neon-green uppercase tracking-[0.3em]">Official Bulletins</p>
            </header>

            <div className="space-y-6">
                {[
                    { title: "System Maintenance", date: "25 Feb", type: "CRITICAL", icon: AlertTriangle, color: "text-rose-500" },
                    { title: "New Policy Update", date: "24 Feb", type: "INFO", icon: Info, color: "text-blue-500" },
                    { title: "General Meeting", date: "22 Feb", type: "GENERAL", icon: Bell, color: "text-neon-green" }
                ].map((notice, i) => (
                    <GlassCard key={i} className="bg-dark-grey border-black hover:bg-white/5 transition-colors">
                        <div className="flex items-center gap-6">
                            <notice.icon className={`w-10 h-10 ${notice.color}`} />
                            <div className="flex-1">
                                <div className="flex justify-between items-start mb-2">
                                    <h3 className="text-xl font-black text-white uppercase">{notice.title}</h3>
                                    <span className="text-[10px] font-black text-white/40">{notice.date}</span>
                                </div>
                                <span className={`px-2 py-0.5 border-2 border-black bg-black text-[8px] font-black ${notice.color} uppercase tracking-widest`}>
                                    {notice.type}
                                </span>
                            </div>
                        </div>
                    </GlassCard>
                ))}
            </div>
        </div>
    );
}
