// SettingsScreen — profile-forward dashboard, not a dense list.
// Bold move: hero card with user+Alex + streak + weekly stats. Vocab & Weekly Report split out.

function HeroCard({ dark }) {
  const c = dark ? KF.dark : KF.light;
  return (
    <div style={{
      margin: '0 14px',
      background: c.card,
      borderRadius: 24,
      padding: 18,
      border: `1px solid ${c.hairline}`,
      boxShadow: dark ? 'none' : '0 1px 2px rgba(30,60,50,0.04)',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
        {/* user avatar placeholder with Alex overlap */}
        <div style={{ position: 'relative', width: 64, height: 56 }}>
          <div style={{
            width: 56, height: 56, borderRadius: '50%',
            background: `repeating-linear-gradient(45deg, ${c.beigeIn} 0 4px, ${c.beige} 4px 8px)`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            fontFamily: KF_TYPE.family, fontSize: 20, fontWeight: 700, color: c.ink2,
            border: `1px solid ${c.hairline}`,
          }}>지</div>
          <div style={{
            position: 'absolute', bottom: -2, right: -6,
            background: c.card, padding: 2, borderRadius: '50%',
          }}>
            <Alex size={26} emotion="celebrate" dark={dark}/>
          </div>
        </div>
        <div style={{ flex: 1 }}>
          <div style={{
            fontFamily: KF_TYPE.family, fontSize: 18, fontWeight: 700,
            color: c.ink, letterSpacing: -0.3,
          }}>지호 · Jiho</div>
          <div style={{
            fontFamily: KF_TYPE.family, fontSize: 12, fontWeight: 500,
            color: c.ink3, marginTop: 3,
          }}>Intermediate · B1 · jiho@email.com</div>
          <div style={{ marginTop: 8, display: 'flex', alignItems: 'center', gap: 8 }}>
            <XPBar value={0.42} dark={dark} width={110}/>
            <span style={{
              fontFamily: KF_TYPE.family, fontSize: 11, fontWeight: 600, color: c.ink3,
            }}>1,240 / 3,000 XP</span>
          </div>
        </div>
      </div>
      {/* stat pills */}
      <div style={{
        marginTop: 14, display: 'grid',
        gridTemplateColumns: '1fr 1fr 1fr', gap: 8,
      }}>
        {[
          { label: 'Streak', value: '14', sub: 'days', icon: 'flame' },
          { label: 'Words', value: '287', sub: 'saved', icon: 'cards' },
          { label: 'This week', value: '1h 42m', sub: 'chatting', icon: 'stats' },
        ].map((s, i) => (
          <div key={i} style={{
            background: c.beige, borderRadius: 14,
            padding: '10px 10px',
          }}>
            <div style={{
              fontFamily: KF_TYPE.family, fontSize: 10, fontWeight: 700,
              color: c.ink3, letterSpacing: 0.4, textTransform: 'uppercase',
            }}>{s.label}</div>
            <div style={{
              fontFamily: KF_TYPE.family, fontSize: 18, fontWeight: 700,
              color: c.ink, marginTop: 2, letterSpacing: -0.4,
              display: 'flex', alignItems: 'baseline', gap: 3,
            }}>
              {s.value}
              <span style={{ fontSize: 10, fontWeight: 600, color: c.ink3 }}>{s.sub}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function SectionTitle({ children, dark }) {
  const c = dark ? KF.dark : KF.light;
  return (
    <div style={{
      padding: '18px 22px 8px',
      fontFamily: KF_TYPE.family, fontSize: 11, fontWeight: 700,
      color: c.ink3, letterSpacing: 0.8, textTransform: 'uppercase',
    }}>{children}</div>
  );
}

function Row({ icon, title, detail, last, dark, tint }) {
  const c = dark ? KF.dark : KF.light;
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: '12px 14px', position: 'relative',
    }}>
      <div style={{
        width: 30, height: 30, borderRadius: 9,
        background: tint || c.beige,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <Icon name={icon} size={16} color={c.ink} strokeWidth={1.9}/>
      </div>
      <div style={{
        flex: 1, fontFamily: KF_TYPE.family, fontSize: 15, fontWeight: 500,
        color: c.ink, letterSpacing: -0.2,
      }}>{title}</div>
      {detail && <span style={{
        fontFamily: KF_TYPE.family, fontSize: 13, fontWeight: 500,
        color: c.ink3,
      }}>{detail}</span>}
      <Icon name="chevr" size={14} color={c.ink3} strokeWidth={2}/>
      {!last && <div style={{
        position: 'absolute', left: 56, right: 14, bottom: 0,
        height: 0.5, background: c.hairline,
      }}/>}
    </div>
  );
}

function Group({ children, dark }) {
  const c = dark ? KF.dark : KF.light;
  return (
    <div style={{
      margin: '0 14px',
      background: c.card, borderRadius: 20,
      border: `1px solid ${c.hairline}`,
      overflow: 'hidden',
    }}>{children}</div>
  );
}

function SettingsScreen({ dark = false }) {
  const c = dark ? KF.dark : KF.light;
  return (
    <div style={{
      display: 'flex', flexDirection: 'column', height: '100%',
      background: c.canvas,
    }}>
      {/* header */}
      <div style={{
        padding: '14px 20px 14px',
        display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      }}>
        <div style={{
          fontFamily: KF_TYPE.family, fontSize: 24, fontWeight: 700,
          color: c.ink, letterSpacing: -0.5,
        }}>Profile</div>
        <div style={{
          width: 34, height: 34, borderRadius: 17,
          background: c.beige,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="close" size={16} color={c.ink2} strokeWidth={2}/>
        </div>
      </div>

      <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 8 }}>
        <HeroCard dark={dark}/>

        <SectionTitle dark={dark}>Learning</SectionTitle>
        <Group dark={dark}>
          <Row dark={dark} icon="cards" title="Vocabulary" detail="287 words" tint={c.sageWash}/>
          <Row dark={dark} icon="stats" title="Weekly report" detail="Mon–Sun" tint={c.mustardSoft}/>
          <Row dark={dark} icon="target" title="Goal" detail="5 min / day"/>
          <Row dark={dark} icon="globe" title="Learning language" detail="English (US)" last/>
        </Group>

        <SectionTitle dark={dark}>Alex</SectionTitle>
        <Group dark={dark}>
          <Row dark={dark} icon="chat" title="Conversation style" detail="Friendly" tint={c.sageWash}/>
          <Row dark={dark} icon="ear" title="Voice & accent" detail="US · Warm"/>
          <Row dark={dark} icon="bell" title="Chat reminders" detail="8:00 AM" last/>
        </Group>

        <SectionTitle dark={dark}>App</SectionTitle>
        <Group dark={dark}>
          <Row dark={dark} icon="moon" title="Appearance" detail="System"/>
          <Row dark={dark} icon="lock" title="Privacy & data"/>
          <Row dark={dark} icon="heart" title="Rate Korean Friend" last/>
        </Group>

        <div style={{ padding: '20px 22px 20px' }}>
          <div style={{
            fontFamily: KF_TYPE.family, fontSize: 12, fontWeight: 500,
            color: c.ink3, textAlign: 'center',
          }}>v2.4.1 · Log out</div>
        </div>
      </div>

      <AdBand dark={dark}/>
    </div>
  );
}

Object.assign(window, { SettingsScreen });
