// Small shared UI bits used by screens.

function Pill({ children, bg, fg, style = {} }) {
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      padding: '4px 9px', borderRadius: 999,
      background: bg, color: fg,
      fontFamily: KF_TYPE.family,
      fontSize: 11, fontWeight: 700, letterSpacing: 0.2,
      ...style,
    }}>{children}</div>
  );
}

// Flame glyph (single path, simple) for streak
function Flame({ size = 10, color }) {
  return (
    <svg width={size} height={size * 1.15} viewBox="0 0 10 12">
      <path d="M5 0C5 3 2 3.5 2 6.5a3 3 0 006 0c0-1.5-1-2.5-1.5-3C6 4.5 5 3 5 0z"
        fill={color}/>
    </svg>
  );
}

// small monochrome glyph pack (stroke-based, consistent weight)
function Icon({ name, size = 20, color = 'currentColor', strokeWidth = 1.8 }) {
  const p = { fill: 'none', stroke: color, strokeWidth, strokeLinecap: 'round', strokeLinejoin: 'round' };
  const common = { width: size, height: size, viewBox: '0 0 24 24' };
  switch (name) {
    case 'chat':    return <svg {...common}><path {...p} d="M4 6.5A2.5 2.5 0 016.5 4h11A2.5 2.5 0 0120 6.5v7a2.5 2.5 0 01-2.5 2.5H10l-4 4v-4H6.5A2.5 2.5 0 014 13.5v-7z"/></svg>;
    case 'home':    return <svg {...common}><path {...p} d="M3.5 11.5L12 4l8.5 7.5M5.5 10v9h4v-5h5v5h4v-9"/></svg>;
    case 'profile': return <svg {...common}><circle {...p} cx="12" cy="8" r="3.5"/><path {...p} d="M4.5 20c1-4 4-6 7.5-6s6.5 2 7.5 6"/></svg>;
    case 'book':    return <svg {...common}><path {...p} d="M4 5.5A1.5 1.5 0 015.5 4H11v15.5H5.5A1.5 1.5 0 014 18V5.5zM20 5.5A1.5 1.5 0 0018.5 4H13v15.5h5.5A1.5 1.5 0 0020 18V5.5z"/></svg>;
    case 'stats':   return <svg {...common}><path {...p} d="M4 20V10M10 20V4M16 20v-7M22 20H2"/></svg>;
    case 'bell':    return <svg {...common}><path {...p} d="M6 9a6 6 0 1112 0c0 5 2 6 2 6H4s2-1 2-6zM10 19a2 2 0 004 0"/></svg>;
    case 'mic':     return <svg {...common}><rect {...p} x="9" y="3" width="6" height="11" rx="3"/><path {...p} d="M5 12a7 7 0 0014 0M12 19v3"/></svg>;
    case 'send':    return <svg {...common}><path {...p} d="M4 12l16-8-6 16-3-7-7-1z"/></svg>;
    case 'sparkle': return <svg {...common}><path {...p} d="M12 3v4M12 17v4M3 12h4M17 12h4M6 6l2.5 2.5M15.5 15.5L18 18M18 6l-2.5 2.5M8.5 15.5L6 18"/></svg>;
    case 'translate': return <svg {...common}><path {...p} d="M4 5h10M9 3v2M11 5c0 4-4 8-7 8M5 9c0 3 3 5 6 5M13 20l4-9 4 9M14.5 17h5"/></svg>;
    case 'chevr':   return <svg {...common}><path {...p} d="M9 6l6 6-6 6"/></svg>;
    case 'chevd':   return <svg {...common}><path {...p} d="M6 9l6 6 6-6"/></svg>;
    case 'close':   return <svg {...common}><path {...p} d="M6 6l12 12M18 6L6 18"/></svg>;
    case 'check':   return <svg {...common}><path {...p} d="M5 12l5 5 9-11"/></svg>;
    case 'plus':    return <svg {...common}><path {...p} d="M12 5v14M5 12h14"/></svg>;
    case 'play':    return <svg width={size} height={size} viewBox="0 0 24 24"><path d="M7 4v16l13-8L7 4z" fill={color}/></svg>;
    case 'ear':     return <svg {...common}><path {...p} d="M8 5a6 6 0 019 5c0 2-2 3-2 5a3 3 0 01-5 2"/></svg>;
    case 'wave':    return <svg {...common}><path {...p} d="M3 12h2M7 8v8M11 5v14M15 8v8M19 10v4M22 12h-1"/></svg>;
    case 'globe':   return <svg {...common}><circle {...p} cx="12" cy="12" r="8"/><path {...p} d="M4 12h16M12 4c3 3 3 13 0 16M12 4c-3 3-3 13 0 16"/></svg>;
    case 'moon':    return <svg {...common}><path {...p} d="M20 14A8 8 0 0110 4a8 8 0 1010 10z"/></svg>;
    case 'heart':   return <svg {...common}><path {...p} d="M12 20s-7-4-7-10a4 4 0 017-2 4 4 0 017 2c0 6-7 10-7 10z"/></svg>;
    case 'lock':    return <svg {...common}><rect {...p} x="5" y="11" width="14" height="10" rx="2"/><path {...p} d="M8 11V8a4 4 0 018 0v3"/></svg>;
    case 'trash':   return <svg {...common}><path {...p} d="M4 7h16M9 7V5a1 1 0 011-1h4a1 1 0 011 1v2M6 7l1 13a2 2 0 002 2h6a2 2 0 002-2l1-13"/></svg>;
    case 'bolt':    return <svg {...common}><path {...p} d="M13 3L5 14h6l-1 7 8-11h-6l1-7z"/></svg>;
    case 'cards':   return <svg {...common}><rect {...p} x="4" y="5" width="16" height="14" rx="2"/><path {...p} d="M4 10h16"/></svg>;
    case 'target':  return <svg {...common}><circle {...p} cx="12" cy="12" r="8"/><circle {...p} cx="12" cy="12" r="3.5"/></svg>;
    default: return null;
  }
}

// Streak chip
function StreakChip({ days = 7, dark = false }) {
  const c = dark ? KF.dark : KF.light;
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      padding: '5px 10px 5px 8px', borderRadius: 999,
      background: dark ? c.mustardSoft : c.mustardSoft,
      color: dark ? c.mustard : 'oklch(0.38 0.1 75)',
      fontFamily: KF_TYPE.family, fontSize: 12, fontWeight: 700,
      letterSpacing: -0.2,
    }}>
      <Flame size={11} color={dark ? c.mustard : 'oklch(0.58 0.16 55)'} />
      {days}
    </div>
  );
}

// XP progress — thin 2px sage bar
function XPBar({ value = 0.64, dark = false, width = '100%' }) {
  const c = dark ? KF.dark : KF.light;
  return (
    <div style={{
      width, height: 3, borderRadius: 2,
      background: c.hairline,
      overflow: 'hidden',
    }}>
      <div style={{
        width: `${value * 100}%`, height: '100%',
        background: c.sage,
        borderRadius: 2,
      }} />
    </div>
  );
}

Object.assign(window, { Pill, Flame, Icon, StreakChip, XPBar });
