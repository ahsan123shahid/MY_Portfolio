import { motion } from 'framer-motion';

export default function Footer() {
  return (
    <footer className="relative z-20 border-t border-white/[0.06] bg-[#0a0a0a] px-6 py-20 sm:px-12 lg:px-24 overflow-hidden">
      <div className="mx-auto max-w-7xl flex flex-col gap-12">
        {/* Footer Top - Call to Action */}
        <div className="flex flex-col md:flex-row justify-between items-start md:items-center gap-6 pb-12 border-b border-white/[0.04]">
          <div>
            <h4 className="text-[10px] font-bold uppercase tracking-[0.25em] text-[#ef4444] mb-2">Next Project</h4>
            <h3 className="text-2xl sm:text-3xl md:text-4xl lg:text-5xl font-black tracking-tight text-white uppercase leading-none">
              Let&apos;s Collaborate
            </h3>
          </div>
          <a
            href="mailto:ahsan123shahid@gmail.com"
            className="group relative w-full sm:w-auto inline-flex items-center justify-center gap-2 overflow-hidden rounded-full bg-white px-6 py-3.5 text-xs font-bold uppercase tracking-[0.15em] text-black transition-transform duration-300 hover:scale-105"
          >
            <span>Start a conversation</span>
            <span className="text-sm font-semibold transition-transform duration-300 group-hover:translate-x-1 group-hover:-translate-y-0.5">
              ↗
            </span>
          </a>
        </div>

        {/* Footer Bottom - Copyright and Social Links */}
        <div className="flex flex-col gap-4 sm:flex-row items-center justify-between text-center sm:text-left">
          <p className="text-[10px] font-semibold uppercase tracking-wider text-white/30">
            &copy; {new Date().getFullYear()} M. Ahsan Shahid. All rights reserved.
          </p>
          <div className="flex items-center gap-6">
            <a
              href="mailto:ahsan123shahid@gmail.com"
              className="text-[10px] font-semibold uppercase tracking-[0.15em] text-white/40 transition-colors duration-300 hover:text-white"
            >
              Email
            </a>
            <a
              href="tel:+923005048126"
              className="text-[10px] font-semibold uppercase tracking-[0.15em] text-white/40 transition-colors duration-300 hover:text-white"
            >
              Phone
            </a>
          </div>
        </div>
      </div>
    </footer>
  );
}
