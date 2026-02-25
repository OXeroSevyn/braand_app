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
            transition={{ duration: 0.5, delay, ease: "easeOut" }}
            whileHover={hover ? { translateX: -4, translateY: -4 } : {}}
            className={cn(
                "glass border-[3px] border-black bg-white shadow-[8px_8px_0px_0px_rgba(0,0,0,1)] p-8 relative overflow-hidden group transition-all duration-200",
                className
            )}
        >
            <div className="relative z-10">
                {children}
            </div>
        </motion.div>
    );
};
