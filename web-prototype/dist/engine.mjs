export const presets = [10,20,30,40,50,60,120,180,240,360,480,720,1440];
export function initialState(now = Date.now()) {
  return {version:1, anchor:now, interval:60, notificationInterval:60, pausedAt:null, pausedSeconds:0, deckOffset:0,
    showMeaning:true, showKana:true, showRomaji:false, dark:false, favorites:[], history:[], reviews:{},
    quietStart:22, quietEnd:8, notifications:false, weekdays:[0,1,2,3,4,5,6]};
}
// A prévia usa o calendário local do navegador. O Swift persiste o fuso explicitamente.
export function activeSeconds(state, start, end) {
  let total=0, cursor=start;
  while(cursor<end) {
    const day=new Date(cursor), next=new Date(cursor);
    next.setHours(24,0,0,0);
    const boundary=Math.min(end,+next);
    if(state.weekdays.includes(day.getDay())) total+=(boundary-cursor)/1000;
    if(boundary<=cursor) break;
    cursor=boundary;
  }
  return total;
}
export function advance(state, start, seconds) {
  if(!state.weekdays.length) throw new Error('Selecione pelo menos um dia.');
  let cursor=start, remaining=Math.max(0,seconds);
  for(;;) {
    const day=new Date(cursor), next=new Date(cursor); next.setHours(24,0,0,0);
    if(state.weekdays.includes(day.getDay())) {
      const available=(+next-cursor)/1000;
      if(remaining<available) return cursor+remaining*1000;
      remaining-=available;
    }
    cursor=+next;
  }
}
export function slot(state, now) {
  const effective=state.pausedAt ?? now;
  let elapsed=Math.max(0,activeSeconds(state,state.anchor,effective)-state.pausedSeconds);
  if(!state.weekdays.includes(new Date(effective).getDay()) && elapsed>0) elapsed=Math.max(0,elapsed-0.000001);
  return Math.floor(elapsed/(state.interval*60));
}
export function wordAt(state, words, now) { return words[(slot(state,now)+(state.deckOffset||0))%words.length]; }
export function nextChange(state, now) {
  if(state.pausedAt !== null) return null;
  const elapsed=Math.max(0,activeSeconds(state,state.anchor,now)-state.pausedSeconds);
  return advance(state,Math.max(now,state.anchor),Math.max(0,(slot(state,now)+1)*state.interval*60-elapsed));
}
export function togglePause(state,now) {
  if(state.pausedAt===null) state.pausedAt=now;
  else {state.pausedSeconds+=activeSeconds(state,state.pausedAt,now);state.pausedAt=null;}
}
export function changeInterval(state,minutes,now) {
  if(!Number.isInteger(minutes)||minutes<1||minutes>10080) throw new Error('Escolha de 1 minuto a 7 dias.');
  state.deckOffset=(state.deckOffset||0)+slot(state,now);
  state.interval=minutes;state.anchor=now;state.pausedSeconds=0;
  if(state.pausedAt!==null) state.pausedAt=now;
}
export function rate(previous, rating, now) {
  const r={due:now,interval:0,ease:2.5,successes:0,lapses:0,...previous};
  if(rating==='again') { r.lapses++;r.successes=0;r.ease=Math.max(1.3,r.ease-.2);r.interval=0;r.due=now+600000;return r; }
  if(rating==='hard') {r.ease=Math.max(1.3,r.ease-.15);r.interval=Math.max(1,r.interval*1.2);}
  if(rating==='good') {r.successes++;r.interval=r.interval===0?1:r.successes===2?3:r.interval*r.ease;}
  if(rating==='easy') {r.successes++;r.ease=Math.min(3,r.ease+.15);r.interval=r.interval===0?4:r.interval*r.ease*1.3;}
  r.interval=Math.min(365,r.interval);r.due=now+r.interval*86400000;return r;
}
export function formatInterval(minutes) {return minutes%60===0?`${minutes/60} h`:`${minutes} min`;}
export function stableHash(value) {
  let hash=14695981039346656037n;
  for(const byte of new TextEncoder().encode(value)) hash=BigInt.asUintN(64,(hash^BigInt(byte))*1099511628211n);
  return hash;
}
