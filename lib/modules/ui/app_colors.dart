import 'package:flutter/material.dart';

/// Design Token Model for the Bento Glassmorphic Design System.
class AppColors {
  final Color bgPrimary;
  final Color bgSecondary;
  final Color cardBg;
  final Color cardHoverBg;
  final Color subCardBg;
  final Color subCardBorder;
  final Color sidebarBg;
  final Color headerBg;
  final Color headerBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color borderDefault;
  final Color accentColor;
  final Color primaryGlow;
  final Color accentCyan;
  final Color accentEmerald;
  final Color accentAmber;
  final Color accentRose;
  final Color accentPurple;

  // Mesh background orbs
  final Color orb1;
  final Color orb2;
  final Color orb3;
  final double orbOpacity;

  // Frosted glass surfaces
  final Color glassBg;
  final Color glassBorder;
  final Color glassHighlight;

  final bool isDark;

  const AppColors({
    this.isDark = false,
    required this.bgPrimary,
    required this.bgSecondary,
    required this.cardBg,
    required this.cardHoverBg,
    required this.subCardBg,
    required this.subCardBorder,
    required this.sidebarBg,
    required this.headerBg,
    required this.headerBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.borderDefault,
    required this.accentColor,
    required this.primaryGlow,
    required this.accentCyan,
    required this.accentEmerald,
    required this.accentAmber,
    required this.accentRose,
    required this.accentPurple,
    required this.orb1,
    required this.orb2,
    required this.orb3,
    required this.orbOpacity,
    required this.glassBg,
    required this.glassBorder,
    required this.glassHighlight,
  });
}

const win11DarkColors = AppColors(
  isDark: true,
  bgPrimary: Colors.transparent, // Let Acrylic bleed through
  bgSecondary: Color(0x14000000), // Very slight tint
  cardBg: Color(0x301E293B), // ~19% slate with backdrop blur
  cardHoverBg: Color(0x4D334155),
  subCardBg: Color(0x240F172A),
  subCardBorder: Color(0x1FFFFFFF),
  sidebarBg: Color(0x29121212),
  headerBg: Color(0x400F172A),
  headerBorder: Color(0x1FFFFFFF),
  textPrimary: Color(0xFFF8FAFC),
  textSecondary: Color(0xFFCBD5E1), // Slate 300 - high contrast readability on dark glass
  textMuted: Color(0xFF94A3B8), // Slate 400 - clean legible muted tone
  borderDefault: Color(0x1FFFFFFF),
  accentColor: Color(0xFF0066FF),
  primaryGlow: Color(0x590066FF),
  accentCyan: Color(0xFF38BDF8),
  accentEmerald: Color(0xFF34D399),
  accentAmber: Color(0xFFFBBF24),
  accentRose: Color(0xFFFB7185),
  accentPurple: Color(0xFFC084FC),
  orb1: Color(0xFF0066FF),
  orb2: Color(0xFFA855F7),
  orb3: Color(0xFF00D2FF),
  orbOpacity: 0.25,
  glassBg: Color(0x331E293B),
  glassBorder: Color(0x1FFFFFFF),
  glassHighlight: Color(0x40FFFFFF),
);

const win11LightColors = AppColors(
  isDark: false,
  bgPrimary: Colors.transparent,
  bgSecondary: Color(0x14FFFFFF),
  cardBg: Color(0x38FFFFFF), // ~22% white with backdrop blur
  cardHoverBg: Color(0x66FFFFFF),
  subCardBg: Color(0x24FFFFFF),
  subCardBorder: Color(0x33FFFFFF),
  sidebarBg: Color(0x29F0F0F0),
  headerBg: Color(0x52FFFFFF),
  headerBorder: Color(0x4DFFFFFF),
  textPrimary: Color(0xFF0F172A),
  textSecondary: Color(0xFF475569),
  textMuted: Color(0xFF64748B),
  borderDefault: Color(0x2EFFFFFF),
  accentColor: Color(0xFF0066FF),
  primaryGlow: Color(0x440066FF),
  accentCyan: Color(0xFF00D2FF),
  accentEmerald: Color(0xFF10B981),
  accentAmber: Color(0xFFF59E0B),
  accentRose: Color(0xFFF43F5E),
  accentPurple: Color(0xFF8B5CF6),
  orb1: Color(0xFF93C5FD), // Soft Pastel Blue
  orb2: Color(0xFFD8B4FE), // Soft Pastel Purple
  orb3: Color(0xFF67E8F9), // Soft Pastel Cyan
  orbOpacity: 0.16,
  glassBg: Color(0x40FFFFFF),
  glassBorder: Color(0x33FFFFFF),
  glassHighlight: Color(0x80FFFFFF),
);

const win10DarkColors = AppColors(
  isDark: true,
  bgPrimary: Colors.transparent,
  bgSecondary: Color(0x14000000), // Subtle dark tint
  cardBg: Color(0x381E293B), // ~22% slate with backdrop blur
  cardHoverBg: Color(0x55334155),
  subCardBg: Color(0x2E0F172A),
  subCardBorder: Color(0x26FFFFFF),
  sidebarBg: Color(0x33121212),
  headerBg: Color(0x4D0F172A),
  headerBorder: Color(0x26FFFFFF),
  textPrimary: Color(0xFFF8FAFC),
  textSecondary: Color(0xFFCBD5E1), // Slate 300 - high contrast readability on dark glass
  textMuted: Color(0xFF94A3B8), // Slate 400 - clean legible muted tone
  borderDefault: Color(0x26FFFFFF),
  accentColor: Color(0xFF0066FF),
  primaryGlow: Color(0x590066FF),
  accentCyan: Color(0xFF38BDF8),
  accentEmerald: Color(0xFF34D399),
  accentAmber: Color(0xFFFBBF24),
  accentRose: Color(0xFFFB7185),
  accentPurple: Color(0xFFC084FC),
  orb1: Color(0xFF0066FF),
  orb2: Color(0xFFA855F7),
  orb3: Color(0xFF00D2FF),
  orbOpacity: 0.22,
  glassBg: Color(0x381E293B),
  glassBorder: Color(0x26FFFFFF),
  glassHighlight: Color(0x4DFFFFFF),
);

const win10LightColors = AppColors(
  isDark: false,
  bgPrimary: Colors.transparent,
  bgSecondary: Color(0x14FFFFFF), // Subtle light tint
  cardBg: Color(0x40FFFFFF), // ~25% white with backdrop blur
  cardHoverBg: Color(0x73FFFFFF),
  subCardBg: Color(0x29FFFFFF),
  subCardBorder: Color(0x33FFFFFF),
  sidebarBg: Color(0x33F0F0F0),
  headerBg: Color(0x59FFFFFF),
  headerBorder: Color(0x4DFFFFFF),
  textPrimary: Color(0xFF0F172A),
  textSecondary: Color(0xFF475569),
  textMuted: Color(0xFF64748B),
  borderDefault: Color(0x33FFFFFF),
  accentColor: Color(0xFF0066FF),
  primaryGlow: Color(0x440066FF),
  accentCyan: Color(0xFF00D2FF),
  accentEmerald: Color(0xFF10B981),
  accentAmber: Color(0xFFF59E0B),
  accentRose: Color(0xFFF43F5E),
  accentPurple: Color(0xFF8B5CF6),
  orb1: Color(0xFF93C5FD), // Soft Pastel Blue
  orb2: Color(0xFFD8B4FE), // Soft Pastel Purple
  orb3: Color(0xFF67E8F9), // Soft Pastel Cyan
  orbOpacity: 0.15,
  glassBg: Color(0x4DFFFFFF),
  glassBorder: Color(0x40FFFFFF),
  glassHighlight: Color(0x80FFFFFF),
);
