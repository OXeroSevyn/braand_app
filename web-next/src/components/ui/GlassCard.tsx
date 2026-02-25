"use client";

import { motion } from "framer-motion";
import { cn } from "@/lib/utils";
import { ReactNode } from "react";

interface GlassCardProps {
    children: ReactNode;
    className?: string;
    hover?: boolean;
    delay?: number;
}

/**
 * GlassCard is now a BrutalCard to match the Cyber-Brutalist theme.
 * Keeping the name for backward compatibility.
 */
export const GlassCard = ({ children, className, hover = true, delay = 0 }: GlassCardProps) => {
    return (
        <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay, ease: [0.16, 1, 0.3, 1] }}
            className={cn(
                "brutal-card rounded-none p-6 relative overflow-hidden group",
                className
            )}
        >
            <div className="relative z-10">
                {children}
            </div>
        </motion.div>
    );
};
