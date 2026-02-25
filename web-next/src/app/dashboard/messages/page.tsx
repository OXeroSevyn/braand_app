"use client";

import { GlassCard } from "@/components/ui/GlassCard";
import { MessageSquare, Users, Bell, CheckSquare } from "lucide-react";

export default function MessagesPage() {
    return (
        <div className="min-h-screen p-6 lg:p-10">
            <header className="mb-12">
                <h1 className="text-4xl md:text-5xl font-black tracking-tighter uppercase text-white">
                    MESSAGES
                </h1>
                <p className="text-[10px] font-bold text-neon-green uppercase tracking-[0.3em]">Team Chat</p>
            </header>

            <GlassCard className="h-[70vh] flex flex-col justify-between bg-dark-grey border-black">
                <div className="p-10 border-b border-white/5 flex items-center gap-6 overflow-x-auto">
                    {[1, 2, 3, 4, 5, 6].map(i => (
                        <div key={i} className="flex flex-col items-center gap-2 shrink-0">
                            <div className="w-14 h-14 rounded-full border-4 border-neon-green bg-black" />
                            <span className="text-[10px] font-bold text-white/40">Team Member</span>
                        </div>
                    ))}
                </div>

                <div className="flex-1 flex items-center justify-center p-10">
                    <p className="text-white/20 font-black uppercase italic tracking-widest">Initializing Secure Channel...</p>
                </div>

                <div className="p-6 border-t border-white/5 flex gap-4">
                    <input className="flex-1 bg-black border-2 border-white/10 p-4 text-white font-bold outline-none focus:border-neon-green transition-colors" placeholder="Type a message..." />
                    <button className="px-8 bg-neon-green text-black font-black uppercase tracking-widest border-2 border-black shadow-[4px_4px_0px_0px_rgba(0,0,0,1)] hover:translate-x-[-2px] hover:translate-y-[-2px] hover:shadow-[6px_6px_0px_0px_rgba(0,0,0,1)] transition-all">Send</button>
                </div>
            </GlassCard>
        </div>
    );
}
