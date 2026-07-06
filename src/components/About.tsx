'use client';

import { motion } from 'framer-motion';

const contact = [
  { label: 'Location', value: 'Rawalpindi, Pakistan', href: 'https://maps.google.com/?q=Rawalpindi,Pakistan' },
  { label: 'Email', value: 'ahsan123shahid@gmail.com', href: 'mailto:ahsan123shahid@gmail.com' },
  { label: 'Phone', value: '+92 300 504 8126', href: 'tel:+923005048126' },
];

export default function About() {
  return (
    <section
      id="about"
      className="relative z-20 bg-[#0a0a0a] px-6 py-32 sm:px-12 lg:px-24"
    >
      {/* Subtle top section line */}
      <div className="absolute top-0 left-12 right-12 h-[1px] bg-gradient-to-r from-white/[0.03] via-white/[0.08] to-white/[0.03]" />

      <div className="mx-auto max-w-7xl">
        <div className="grid gap-16 lg:grid-cols-[1fr_360px]">
          {/* Left Column: Title, Slogan, and Callout */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            whileInView={{ opacity: 1, y: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, ease: [0.25, 0.1, 0.25, 1] }}
          >
            <span className="inline-block mb-3 text-xs font-semibold uppercase tracking-[0.25em] text-[#ef4444]">
              About Me
            </span>
            <h2 className="text-3xl sm:text-4xl md:text-5xl font-black leading-[0.95] tracking-tighter uppercase text-white mb-6 select-none">
              APPLIED AI ENGINEER. <br />
              BRIDGING THEORY AND <span className="text-[#ef4444]">DEPLOYMENT.</span>
            </h2>
            <p className="text-sm sm:text-base leading-relaxed text-white/50 mb-8 max-w-3xl">
              I am a final-year BS AI student specializing in hands-on artificial intelligence engineering. I build custom, scalable RAG setups and REST APIs. I focus on understanding underlying model properties, search latency scaling, and deployment architectures—not just integrating API wrappers.
            </p>

            {/* Featured Project Callout */}
            <div className="relative overflow-hidden rounded-2xl border border-white/[0.06] bg-white/[0.01] p-6 backdrop-blur-md">
              <div className="absolute left-0 top-0 bottom-0 w-[3px] bg-[#ef4444]" />
              <h4 className="text-[10px] font-bold uppercase tracking-[0.15em] text-[#ef4444] mb-2">Research &amp; Production Showcase</h4>
              <h5 className="text-sm font-bold text-white mb-1.5">MathsPrep AI — Final Year Project</h5>
              <p className="text-xs sm:text-sm text-white/50 leading-relaxed">
                Uses advanced RAG pipelines and Large Language Models to parse raw academic lecture PDFs, extract relevant topics, and automatically generate multi-format math quizzes. Integrates vector search databases (Chroma/FAISS) with a fully responsive cross-platform Flutter application.
              </p>
            </div>
          </motion.div>

          {/* Right Column: Statistics & Quick Contacts */}
          <motion.div
            initial={{ opacity: 0, x: 25 }}
            whileInView={{ opacity: 1, x: 0 }}
            viewport={{ once: true }}
            transition={{ duration: 0.6, delay: 0.15, ease: [0.25, 0.1, 0.25, 1] }}
            className="flex flex-col gap-8 justify-start"
          >
            {/* Stats Panel */}
            <div className="grid gap-6 border-b border-white/[0.05] pb-8">
              <div className="flex gap-5 items-center">
                <span className="text-6xl font-black leading-none text-[#ef4444] tracking-tighter">1+</span>
                <div>
                  <h4 className="text-[10px] font-bold uppercase tracking-wider text-white/80 mt-1">Years Experience</h4>
                  <p className="text-xs text-white/40">Crafting active databases &amp; backend tools</p>
                </div>
              </div>

              <div className="flex gap-5 items-center">
                <span className="text-6xl font-black leading-none text-[#ef4444] tracking-tighter">100%</span>
                <div>
                  <h4 className="text-[10px] font-bold uppercase tracking-wider text-white/80 mt-1">Applied AI</h4>
                  <p className="text-xs text-white/40">Practical pipelines, RAG, and vector search</p>
                </div>
              </div>
            </div>

            {/* Quick Contacts */}
            <div className="flex flex-col gap-3">
              <span className="text-[10px] font-bold uppercase tracking-[0.2em] text-white/30 border-b border-white/5 pb-2">
                Get in Touch
              </span>
              {contact.map((c) => (
                <a
                  key={c.label}
                  href={c.href}
                  target={c.href.startsWith('http') ? '_blank' : undefined}
                  rel={c.href.startsWith('http') ? 'noopener noreferrer' : undefined}
                  className="group flex flex-col p-4 rounded-xl border border-white/[0.04] bg-white/[0.01] transition-all duration-300 hover:border-[#ef4444]/30 hover:bg-white/[0.02]"
                >
                  <span className="text-[9px] font-bold uppercase tracking-[0.2em] text-white/40 group-hover:text-[#ef4444] transition-colors duration-300">
                    {c.label}
                  </span>
                  <span className="text-sm text-white/70 group-hover:text-white transition-colors duration-300 mt-1 flex items-center gap-1">
                    {c.value}
                    <span className="opacity-0 -translate-x-1 group-hover:opacity-100 group-hover:translate-x-0 transition-all duration-300 text-[#ef4444] text-xs">
                      ↗
                    </span>
                  </span>
                </a>
              ))}
            </div>
          </motion.div>
        </div>
      </div>
    </section>
  );
}
