'use client';

import { motion } from 'framer-motion';

export default function WhatsAppButton() {
  return (
    <motion.a
      href="https://wa.me/923005048126?text=Hi%20Ahsan,%20I%20saw%20your%20portfolio%20and%20would%20love%20to%20connect!"
      target="_blank"
      rel="noopener noreferrer"
      initial={{ opacity: 0, scale: 0.8 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{ delay: 1, duration: 0.5 }}
      whileHover={{ scale: 1.1 }}
      whileTap={{ scale: 0.9 }}
      className="fixed bottom-[48px] right-[108px] z-50 flex h-20 w-20 items-center justify-center rounded-full bg-gradient-to-tr from-[#25D366] to-[#128C7E] text-white shadow-[0_4px_20px_rgba(37,211,102,0.35)] hover:shadow-[0_4px_30px_rgba(37,211,102,0.55)] transition-shadow duration-300 cursor-pointer"
      aria-label="Chat on WhatsApp"
    >
      {/* Outer pulsing animation ring */}
      <span className="absolute -inset-1.5 rounded-full border-2 border-[#25D366]/30 animate-ping pointer-events-none" />

      {/* WhatsApp SVG Icon */}
      <svg
        className="w-10 h-10 fill-current"
        viewBox="0 0 24 24"
        xmlns="http://www.w3.org/2000/svg"
      >
        <path d="M.057 24l1.687-6.163c-1.041-1.804-1.588-3.849-1.587-5.946C.06 5.348 5.397.01 12.008.01c3.202.001 6.212 1.246 8.477 3.514 2.266 2.268 3.507 5.28 3.505 8.484-.004 6.657-5.34 11.997-11.953 11.997-2.005-.001-3.973-.502-5.724-1.457L0 24zm6.59-4.846c1.6.95 3.188 1.449 4.825 1.451 5.436 0 9.86-4.37 9.864-9.799.002-2.63-1.023-5.101-2.885-6.965C16.638 1.977 14.17 1.95 12.003 1.95c-5.439 0-9.865 4.37-9.869 9.802-.001 1.77.463 3.5 1.34 5.03l-.997 3.64 3.738-.97c1.512.825 3.036 1.258 4.832 1.258zm10.743-7.394c-.29-.145-1.716-.848-1.982-.944-.265-.096-.458-.145-.65.145-.193.29-.747.944-.916 1.137-.168.193-.337.217-.627.072-1.39-.699-2.28-1.22-3.188-2.78-.24-.412.24-.382.688-1.277.073-.145.036-.273-.018-.382-.054-.109-.458-1.109-.627-1.518-.164-.396-.346-.341-.475-.347-.123-.006-.264-.007-.407-.007-.143 0-.377.054-.574.271-.197.217-.747.73-.747 1.78s.766 2.062.871 2.206c.105.144 1.507 2.302 3.65 3.228 1.05.453 1.869.724 2.508.927.708.225 1.353.193 1.862.117.568-.085 1.717-.702 1.958-1.381.24-.68.24-1.261.169-1.381-.07-.12-.262-.217-.552-.363z" />
      </svg>
    </motion.a>
  );
}
