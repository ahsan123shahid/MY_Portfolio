'use client';

import { motion } from 'framer-motion';
import { FormEvent, useState } from 'react';

export default function ContactForm() {
  const [formData, setFormData] = useState({ name: '', email: '', type: '', message: '' });
  const [status, setStatus] = useState<'idle' | 'sending' | 'success'>('idle');

  function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setStatus('sending');
    setTimeout(() => {
      setStatus('success');
      setFormData({ name: '', email: '', type: '', message: '' });
      setTimeout(() => setStatus('idle'), 3000);
    }, 1500);
  }

  return (
    <section id="contact" className="relative z-20 bg-[#0a0a0a] px-6 py-32 sm:px-12 lg:px-24">
      {/* Subtle top line */}
      <div className="absolute top-0 left-12 right-12 h-[1px] bg-gradient-to-r from-white/[0.03] via-white/[0.08] to-white/[0.03]" />

      <div className="mx-auto max-w-7xl">
        <div className="grid gap-16 lg:grid-cols-12 items-start">
          {/* Left Column: Bold title and coordinates */}
          <div className="lg:col-span-5 text-left">
            <span className="inline-block mb-3 text-xs font-semibold uppercase tracking-[0.25em] text-[#ef4444]">
              Start a project
            </span>
            <h2 className="text-2xl sm:text-4xl md:text-5xl lg:text-6xl font-black leading-[0.95] tracking-tighter uppercase text-white mb-8 sm:mb-10 select-none">
              LET&apos;S CREATE <br />
              SOMETHING <span className="text-[#ef4444]">BOLD.</span>
            </h2>

            {/* Coordinates list */}
            <div className="space-y-6">
              <a
                href="mailto:ahsan123shahid@gmail.com"
                className="group flex items-center gap-4 p-4 rounded-xl border border-white/[0.04] bg-white/[0.01] transition-all duration-300 hover:border-[#ef4444]/30 hover:bg-white/[0.02]"
              >
                <div className="p-2.5 rounded-lg border border-white/[0.05] bg-white/[0.01] text-[#ef4444]">
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                  </svg>
                </div>
                <div>
                  <h4 className="text-[10px] font-bold uppercase tracking-wider text-white/30">Email Me</h4>
                  <p className="text-sm font-semibold text-white/70 group-hover:text-white transition-colors duration-300">
                    ahsan123shahid@gmail.com
                  </p>
                </div>
              </a>

              <a
                href="tel:+923005048126"
                className="group flex items-center gap-4 p-4 rounded-xl border border-white/[0.04] bg-white/[0.01] transition-all duration-300 hover:border-[#ef4444]/30 hover:bg-white/[0.02]"
              >
                <div className="p-2.5 rounded-lg border border-white/[0.05] bg-white/[0.01] text-[#ef4444]">
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.94.725l.548 2.2a1 1 0 01-.321.988l-1.305.98a10.582 10.582 0 004.872 4.872l.98-1.305a1 1 0 01.988-.321l2.2.548a1 1 0 01.725.94V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                  </svg>
                </div>
                <div>
                  <h4 className="text-[10px] font-bold uppercase tracking-wider text-white/30">Call Me</h4>
                  <p className="text-sm font-semibold text-white/70 group-hover:text-white transition-colors duration-300">
                    +92 300 504 8126
                  </p>
                </div>
              </a>

              <div className="flex items-center gap-4 p-4 rounded-xl border border-white/[0.04] bg-white/[0.01]">
                <div className="p-2.5 rounded-lg border border-white/[0.05] bg-white/[0.01] text-[#ef4444]">
                  <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                    <path strokeLinecap="round" strokeLinejoin="round" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                </div>
                <div>
                  <h4 className="text-[10px] font-bold uppercase tracking-wider text-white/30">Location</h4>
                  <p className="text-sm font-semibold text-white/70">
                    Rawalpindi, Pakistan
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Right Column: Contact Form */}
          <div className="lg:col-span-7 bg-white/[0.01] border border-white/[0.05] rounded-2xl p-5 sm:p-8 md:p-12 backdrop-blur-md">
            <form onSubmit={handleSubmit} className="space-y-6">
              <div className="grid gap-6 sm:grid-cols-2">
                {/* Name */}
                <div className="flex flex-col text-left">
                  <label className="text-[10px] font-bold uppercase tracking-wider text-white/40 mb-2">Your Name</label>
                  <input
                    type="text"
                    required
                    placeholder="Enter your name"
                    value={formData.name}
                    onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                    className="rounded-lg border border-white/10 bg-transparent px-4 py-3 text-sm text-white placeholder-white/20 outline-none transition-colors duration-300 focus:border-[#ef4444]"
                  />
                </div>

                {/* Email */}
                <div className="flex flex-col text-left">
                  <label className="text-[10px] font-bold uppercase tracking-wider text-white/40 mb-2">Your Email</label>
                  <input
                    type="email"
                    required
                    placeholder="Enter your email"
                    value={formData.email}
                    onChange={(e) => setFormData({ ...formData, email: e.target.value })}
                    className="rounded-lg border border-white/10 bg-transparent px-4 py-3 text-sm text-white placeholder-white/20 outline-none transition-colors duration-300 focus:border-[#ef4444]"
                  />
                </div>
              </div>

              {/* Project Type */}
              <div className="flex flex-col text-left">
                <label className="text-[10px] font-bold uppercase tracking-wider text-white/40 mb-2">Project Type</label>
                <select
                  required
                  value={formData.type}
                  onChange={(e) => setFormData({ ...formData, type: e.target.value })}
                  className="rounded-lg border border-white/10 bg-[#0a0a0a] px-4 py-3 text-sm text-white/70 outline-none transition-colors duration-300 focus:border-[#ef4444]"
                >
                  <option value="" disabled>Select project type</option>
                  <option value="ai">AI / RAG Integration</option>
                  <option value="api">Backend &amp; API Development</option>
                  <option value="mobile">Flutter Mobile App</option>
                  <option value="fullstack">Full-Stack Solution</option>
                </select>
              </div>

              {/* Message */}
              <div className="flex flex-col text-left">
                <label className="text-[10px] font-bold uppercase tracking-wider text-white/40 mb-2">Tell me about your project</label>
                <textarea
                  required
                  rows={4}
                  placeholder="Describe your goals, tech stack, and timeline..."
                  value={formData.message}
                  onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                  className="rounded-lg border border-white/10 bg-transparent px-4 py-3 text-sm text-white placeholder-white/20 outline-none resize-none transition-colors duration-300 focus:border-[#ef4444]"
                />
              </div>

              {/* Submit button */}
              <div className="flex justify-end pt-4">
                <button
                  type="submit"
                  disabled={status !== 'idle'}
                  className="group w-full sm:w-auto inline-flex items-center justify-center gap-3 rounded-lg bg-[#ef4444] px-8 py-4 text-xs font-bold uppercase tracking-[0.20em] text-white transition-all duration-300 hover:bg-[#ff3333] hover:shadow-[0_0_30px_rgba(239,68,68,0.3)] disabled:bg-white/10 disabled:text-white/40 cursor-pointer"
                >
                  {status === 'idle' && (
                    <>
                      <span>Send Message</span>
                      <span className="text-xs transition-transform duration-300 group-hover:translate-x-0.5 group-hover:-translate-y-0.5">
                        ↗
                      </span>
                    </>
                  )}
                  {status === 'sending' && <span>Sending...</span>}
                  {status === 'success' && <span>Message Sent!</span>}
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>
    </section>
  );
}
