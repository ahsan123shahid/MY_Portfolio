'use client';

import { motion } from 'framer-motion';

export default function Testimonial() {
  return (
    <section className="relative z-20 bg-[#0a0a0a] px-6 py-24 sm:px-12 lg:px-24 overflow-hidden">
      {/* Subtle top line */}
      <div className="absolute top-0 left-12 right-12 h-[1px] bg-gradient-to-r from-white/[0.03] via-white/[0.08] to-white/[0.03]" />

      <div className="mx-auto max-w-7xl">
        <div className="relative rounded-2xl border border-white/[0.05] bg-white/[0.01] p-8 sm:p-12 md:p-16 backdrop-blur-md">
          {/* Top highlight indicator */}
          <div className="absolute top-0 left-12 right-12 h-[1px] bg-gradient-to-r from-transparent via-[#ef4444]/20 to-transparent" />

          <div className="grid gap-10 md:grid-cols-[auto_1fr_auto] items-center">
            {/* Giant quote mark symbol */}
            <span className="text-8xl font-serif font-black text-[#ef4444] leading-none select-none select-none block text-left md:text-center md:pb-8">
              “
            </span>

            {/* Quote details */}
            <div className="text-left">
              <blockquote className="text-lg sm:text-xl md:text-2xl font-bold leading-relaxed text-white/90 mb-8 italic">
                &ldquo;Ahsan&apos;s implementation of our FastAPI CRM and custom AI parsing scripts completely transformed our UK energy lead pipelines. He resolved critical serverless DB leaks and automated unstructured data parsing that saves our sales desk hours every day.&rdquo;
              </blockquote>
              
              <div className="flex items-center gap-4">
                {/* Custom Client Avatar Placeholder with Red Halo */}
                <div className="relative h-12 w-12 shrink-0 rounded-full border border-[#ef4444]/30 bg-gradient-to-br from-[#ef4444]/10 to-[#0a0a0a] flex items-center justify-center font-bold text-xs text-white">
                  JC
                </div>
                <div>
                  <h4 className="text-sm font-black uppercase text-white tracking-wider">James Carter</h4>
                  <p className="text-xs text-white/40 font-semibold uppercase tracking-wider">Managing Director, RT International</p>
                </div>
              </div>
            </div>

            {/* Quote navigation controls */}
            <div className="flex items-center gap-2 mt-4 md:mt-0">
              <button className="h-10 w-10 rounded-full border border-white/10 bg-transparent flex items-center justify-center text-white/40 hover:border-[#ef4444] hover:text-[#ef4444] hover:bg-[#ef4444]/5 transition-all duration-300">
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M15 19l-7-7 7-7" />
                </svg>
              </button>
              <button className="h-10 w-10 rounded-full border border-white/10 bg-transparent flex items-center justify-center text-white/40 hover:border-[#ef4444] hover:text-[#ef4444] hover:bg-[#ef4444]/5 transition-all duration-300">
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M9 5l7 7-7 7" />
                </svg>
              </button>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
