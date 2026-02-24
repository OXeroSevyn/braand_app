"use client";

import { motion } from "framer-motion";
import React from "react";

export const AuraBackground = () => {
    return (
        <div className="fixed inset-0 -z-10 overflow-hidden bg-background">
            {/* Primary Aura */}
            <motion.div
                animate={{
                    scale: [1, 1.2, 1],
                    x: [0, 100, 0],
                    y: [0, 50, 0],
                }}
                transition={{
                    duration: 20,
                    repeat: Infinity,
                    ease: "linear",
                }}
                className="absolute -top-[10%] -left-[10%] h-[60%] w-[60%] rounded-full bg-aura-1/20 blur-[120px]"
            />

            {/* Secondary Aura */}
            <motion.div
                animate={{
                    scale: [1, 1.3, 1],
                    x: [0, -80, 0],
                    y: [0, 120, 0],
                }}
                transition={{
                    duration: 25,
                    repeat: Infinity,
                    ease: "linear",
                }}
                className="absolute top-[20%] -right-[10%] h-[50%] w-[50%] rounded-full bg-aura-2/20 blur-[100px]"
            />

            {/* Tertiary Aura */}
            <motion.div
                animate={{
                    scale: [1, 1.1, 1],
                    x: [0, 40, 0],
                    y: [0, -60, 0],
                }}
                transition={{
                    duration: 18,
                    repeat: Infinity,
                    ease: "linear",
                }}
                className="absolute bottom-[-10%] left-[20%] h-[40%] w-[40%] rounded-full bg-aura-3/20 blur-[140px]"
            />

            {/* Noise Texture Overlay */}
            <div className="absolute inset-0 opacity-[0.03] pointer-events-none bg-[url('https://grainy-gradients.vercel.app/noise.svg')]" />
        </div>
    );
};
