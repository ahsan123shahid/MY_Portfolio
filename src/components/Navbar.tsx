'use client';

import { useEffect, useState } from 'react';
import { motion, useScroll, useTransform, AnimatePresence } from 'framer-motion';

const links = ['About', 'Experience', 'Projects', 'Contact'];

export default function Navbar() {
  const { scrollY } = useScroll();
  const [activeSection, setActiveSection] = useState('');
  const [mobileOpen, setMobileOpen] = useState(false);

  const bg = useTransform(
    scrollY,
    [0, 150],
    ['rgba(18, 18, 18, 0)', 'rgba(18, 18, 18, 0.85)']
  );
  
  const border = useTransform(
    scrollY,
    [0, 150],
    ['rgba(255, 255, 255, 0)', 'rgba(255, 255, 255, 0.05)']
  );

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            setActiveSection(entry.target.id);
          }
        });
      },
      { threshold: 0.25, rootMargin: '-20% 0px -50% 0px' }
    );

    const sections = ['about', 'experience', 'projects', 'contact'];
    sections.forEach((id) => {
      const el = document.getElementById(id);
      if (el) observer.observe(el);
    });

    return () => observer.disconnect();
  }, []);

  // Lock body scroll when mobile menu is open
  useEffect(() => {
    if (mobileOpen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = '';
    }
    return () => { document.body.style.overflow = ''; };
  }, [mobileOpen]);

  return (
    <>
      <motion.header
        style={{ background: bg, borderColor: border }}
        className="fixed top-0 left-0 right-0 z-50 flex items-center justify-between px-5 py-4 sm:px-12 border-b backdrop-blur-md transition-all duration-300"
      >
        <div className="flex items-center gap-1.5 select-none">
          <span className="text-sm font-black tracking-[0.2em] text-white">AHSAN</span>
          <span className="h-1.5 w-1.5 rounded-full bg-[#ef4444] animate-pulse" />
        </div>

        {/* Desktop nav */}
        <nav className="hidden sm:flex items-center gap-8">
          {links.map((l) => {
            const id = l.toLowerCase();
            const isActive = activeSection === id;
            return (
              <a
                key={l}
                href={`#${id}`}
                className={`relative text-[10px] font-bold tracking-[0.2em] uppercase transition-colors duration-300 ${
                  isActive ? 'text-[#ef4444]' : 'text-white/40 hover:text-white/80'
                }`}
              >
                {l}
                {isActive && (
                  <motion.span
                    layoutId="activeIndicator"
                    className="absolute -bottom-1 left-0 right-0 h-[1.5px] bg-[#ef4444]"
                    transition={{ type: 'spring', stiffness: 380, damping: 30 }}
                  />
                )}
              </a>
            );
          })}
        </nav>

        {/* Desktop contact button */}
        <motion.a
          whileHover={{ scale: 1.03 }}
          whileTap={{ scale: 0.98 }}
          href="mailto:ahsan123shahid@gmail.com"
          className="hidden sm:inline-flex rounded-full border border-white/[0.12] bg-white/[0.01] px-5 py-2 text-[10px] font-bold tracking-[0.15em] uppercase text-white/80 transition-colors duration-300 hover:border-[#ef4444]/30 hover:bg-[#ef4444]/5 hover:text-white cursor-pointer"
        >
          Contact
        </motion.a>

        {/* Mobile hamburger button */}
        <button
          onClick={() => setMobileOpen(!mobileOpen)}
          className="sm:hidden flex flex-col items-center justify-center w-10 h-10 gap-[5px] cursor-pointer relative z-[60]"
          aria-label="Toggle mobile menu"
        >
          <motion.span
            animate={mobileOpen ? { rotate: 45, y: 7 } : { rotate: 0, y: 0 }}
            transition={{ duration: 0.3 }}
            className="block w-6 h-[2px] bg-white rounded-full origin-center"
          />
          <motion.span
            animate={mobileOpen ? { opacity: 0, scaleX: 0 } : { opacity: 1, scaleX: 1 }}
            transition={{ duration: 0.2 }}
            className="block w-6 h-[2px] bg-white rounded-full"
          />
          <motion.span
            animate={mobileOpen ? { rotate: -45, y: -7 } : { rotate: 0, y: 0 }}
            transition={{ duration: 0.3 }}
            className="block w-6 h-[2px] bg-white rounded-full origin-center"
          />
        </button>
      </motion.header>

      {/* Mobile menu overlay */}
      <AnimatePresence>
        {mobileOpen && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            transition={{ duration: 0.3 }}
            className="fixed inset-0 z-40 bg-[#0a0a0a]/95 backdrop-blur-xl sm:hidden"
          >
            <nav className="flex flex-col items-center justify-center h-full gap-8">
              {links.map((l, i) => {
                const id = l.toLowerCase();
                const isActive = activeSection === id;
                return (
                  <motion.a
                    key={l}
                    href={`#${id}`}
                    onClick={() => setMobileOpen(false)}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: -10 }}
                    transition={{ duration: 0.3, delay: i * 0.08 }}
                    className={`text-2xl font-black tracking-[0.15em] uppercase transition-colors duration-300 ${
                      isActive ? 'text-[#ef4444]' : 'text-white/60'
                    }`}
                  >
                    {l}
                  </motion.a>
                );
              })}
              <motion.a
                href="mailto:ahsan123shahid@gmail.com"
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -10 }}
                transition={{ duration: 0.3, delay: links.length * 0.08 }}
                className="mt-4 rounded-full border border-[#ef4444]/40 bg-[#ef4444]/10 px-8 py-3.5 text-xs font-bold tracking-[0.2em] uppercase text-white transition-all duration-300 hover:bg-[#ef4444]/20"
              >
                Get In Touch
              </motion.a>
            </nav>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
}
