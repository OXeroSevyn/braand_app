"use client";

import { motion } from "framer-motion";
import { cn } from "@/lib/utils";
import React from "react";

interface GlassCardProps {
    children: React.ReactNode;
    className?: string;
    hover?: boolean;
    delay?: number;
}

export const GlassCard = ({ children, className, hover = true, delay = 0 }: GlassCardProps) => {
    return (
        <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, delay, ease: [0.16, 1, 0.3, 1] }}
            whileHover={hover ? { scale: 1.01, translateY: -4 } : {}}
            className={cn(
                "glass rounded-[2rem] p-8 relative overflow-hidden group",
                className
            )}
        >
            {/* Subtle highlight effect on hover */}
            <div className="absolute inset-0 bg-gradient-to-br from-white/5 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />

            <div className="relative z-10">
                {children}
            </div>
        </motion.div>
    );
};
