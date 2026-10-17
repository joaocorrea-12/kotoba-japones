import {presets,initialState,wordAt,slot,nextChange,togglePause,changeInterval,rate,formatInterval} from './engine.mjs';

const main=document.querySelector('main'), dialog=document.querySelector('dialog');
const esc=value=>String(value).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const dateLabel=value=>new Date(value).toLocaleDateString('pt-BR',{weekday:'long',day:'numeric',month:'long'});
const dateTime=value=>new Date(value).toLocaleString('pt-BR',{day:'2-digit',month:'2-digit',hour:'2-digit',minute:'2-digit'});
let words=[], offset=0, currentID='', revealed=false, libraryFilter='all', query='', widgetSize='small', toastTimer;
let state=initialState();
try {
  const saved=JSON.parse(localStorage.getItem('kotoba-preview-v1'));
  if(saved?.version===1 && Number.isInteger(saved.interval) && saved.interval>=1 && saved.interval<=10080 &&
    Number.isFinite(saved.anchor) && Array.isArray(saved.weekdays) && saved.weekdays.length>0 &&
    saved.weekdays.every(x=>Number.isInteger(x)&&x>=0&&x<=6) && Array.isArray(saved.favorites)&&Array.isArray(saved.history)&&
    saved.reviews && typeof saved.reviews==='object' && Number.isFinite(saved.pausedSeconds) && saved.pausedSeconds>=0 &&
    (saved.pausedAt===null||Number.isFinite(saved.pausedAt))) state={...state,...saved};
} catch { /* O app continua em memória se o navegador bloquear o armazenamento. */ }
const now=()=>Date.now()+offset;
const route=()=>['today','words','review','settings'].includes(location.hash.slice(1))?location.hash.slice(1):'today';
const current=()=>wordAt(state,words,now());
const favorite=id=>state.favorites.includes(id);
const dayKey=time=>new Date(time).toLocaleDateString('en-CA');
const todayCount=()=>new Set(state.history.filter(h=>dayKey(h.time)===dayKey(now())).map(h=>h.id)).size;
const dueWords=()=>words.filter(w=>state.history.some(h=>h.id===w.id)&&(!state.reviews[w.id]||state.reviews[w.id].due<=now()));
function save(){try{localStorage.setItem('kotoba-preview-v1',JSON.stringify(state));}catch{toast('O navegador bloqueou a gravação. Esta sessão continua funcionando.');}}
function toast(message){const el=document.querySelector('#toast');el.textContent=message;el.classList.add('show');clearTimeout(toastTimer);toastTimer=setTimeout(()=>el.classList.remove('show'),4500);}
function markSeen(word){if(!state.history.some(h=>h.id===word.id&&dayKey(h.time)===dayKey(now()))){state.history.unshift({id:word.id,time:now()});save();}}
function streak(){const days=new Set(state.history.map(h=>dayKey(h.time)));const date=new Date(now());let count=0;if(!days.has(dayKey(+date)))date.setDate(date.getDate()-1);while(days.has(dayKey(+date))){count++;date.setDate(date.getDate()-1);}return count;}
function speech(word){
  if(!('speechSynthesis' in window)){toast('A síntese de voz não está disponível neste navegador.');return;}
  const voices=speechSynthesis.getVoices(), voice=voices.find(v=>v.lang.startsWith('ja'));
  if(!voice){toast('Este navegador não tem uma voz japonesa disponível. No iOS nativo, o Kotoba usará a voz do sistema.');return;}
  speechSynthesis.cancel();const utterance=new SpeechSynthesisUtterance(word.japanese);utterance.voice=voice;utterance.lang='ja-JP';utterance.rate=.8;speechSynthesis.speak(utterance);
}
function wordCard(word,caption='PALAVRA DO MOMENTO'){
  return `<article class="card word-card"><div class="word-top"><span class="eyebrow"><span aria-hidden="true">✳</span> ${caption}</span><span class="level">JLPT N${word.jlpt}</span></div>
    <div class="word-face"><h2 class="japanese" lang="ja">${esc(word.japanese)}</h2>${state.showKana?`<p class="kana" lang="ja">${esc(word.kana)}</p>`:''}${state.showRomaji?`<p class="romaji">${esc(word.romaji)}</p>`:''}${state.showMeaning?`<p class="meaning">${esc(word.meaning)}</p>`:''}<span class="grammar">${esc(word.partOfSpeech)}</span></div>
    <div class="button-row"><button class="btn primary" data-action="speak" data-id="${word.id}"><span aria-hidden="true">♫</span> Ouvir pronúncia</button><button class="btn ${favorite(word.id)?'saved':''}" data-action="favorite" data-id="${word.id}" aria-pressed="${favorite(word.id)}"><span aria-hidden="true">${favorite(word.id)?'▣':'▢'}</span> ${favorite(word.id)?'Palavra salva':'Salvar palavra'}</button></div>
    <div class="example"><span class="eyebrow">NO DIA A DIA</span><p class="jp" lang="ja">${esc(word.example)}</p>${state.showMeaning?`<p class="pt">${esc(word.exampleMeaning)}</p>`:''}</div><p class="note">${esc(word.note)}</p></article>`;
}
function widget(word){return `<div class="widget-preview ${widgetSize}" aria-label="Simulação de widget ${widgetSize}"><div class="widget-label"><span>KOTOBA</span><span>N${word.jlpt}</span></div><div class="widget-word" lang="ja">${esc(word.japanese)}</div>${state.showKana?`<p class="widget-kana" lang="ja">${esc(word.kana)}</p>`:''}${state.showMeaning?`<p class="widget-meaning">${esc(word.meaning)}</p>`:''}${widgetSize==='large'?`<p class="widget-kana" lang="ja" style="margin-top:20px">${esc(word.example)}</p>`:''}</div>`;}
function header(title,eyebrow,description,extra=''){return `<div class="page-heading"><div><span class="eyebrow">${eyebrow}</span><h1>${title}</h1><p class="subtitle">${description}</p></div>${extra}</div>`;}
function today(){
  const word=current();markSeen(word);
  const next=nextChange(state,now()), count=todayCount();
  return `${header('Um pouco,<br>todos os dias.','SEU PEQUENO ENCONTRO COM O JAPONÊS',dateLabel(now()),`<div class="streak"><span aria-hidden="true">♧</span><b>${streak()}</b> <span class="days-label">${streak()===1?'dia':'dias'} de constância</span></div>`)}
    <div class="home-grid"><div class="left-column">${wordCard(word)}<div class="card rhythm-card"><div class="round-icon" aria-hidden="true">◷</div><div><h3>${state.pausedAt!==null?'Uma pausa também faz parte.':`Uma palavra a cada ${formatInterval(state.interval)}`}</h3><p>${next?`Próxima troca: <span data-next>${dateTime(next)}</span>`:'Trocas e avisos pausados'}</p></div><a href="#settings" aria-label="Ajustar intervalo">↗</a></div></div>
    <div class="right-column"><section class="card"><div class="section-top"><h2>Passo a passo</h2><small>SUA META DIÁRIA</small></div><div class="progress-line"><b>Palavras de hoje</b><span>${count} <span style="color:var(--muted)">/ 5</span></span></div><progress value="${Math.min(count,5)}" max="5" aria-label="Palavras estudadas hoje"></progress><p class="progress-note">${count>=5?'Seu encontro de hoje está completo. Que tal uma revisão?':'Cada palavra é um novo jeito de ver o mundo.'}</p><a href="#review" class="review-link"><span aria-hidden="true">▱</span><span>${dueWords().length} ${dueWords().length===1?'palavra para revisitar':'palavras para revisitar'}</span><span>→</span></a></section>
    <section class="widget-panel"><div class="section-top"><h2>Leve uma<br>palavra com você.</h2></div>${widget(word)}<div class="preview-sizes">${[['small','P'],['medium','M'],['large','G']].map(([key,label])=>`<button data-size="${key}" class="${widgetSize===key?'selected':''}" aria-label="Widget ${key==='small'?'pequeno':key==='medium'?'médio':'grande'}" aria-pressed="${widgetSize===key}">${label}</button>`).join('')}</div><p class="widget-foot">Um lembrete gentil na sua tela.<br>Simulação visual; no iPhone, use o widget nativo.</p><a class="text-link" href="#settings">Personalizar meu ritmo ↗</a></section>
    <div class="quote-card"><span class="quote-jp" lang="ja">一歩ずつ</span><p><b>Um passo de cada vez.</b><br>Não é preciso aprender tudo hoje.<br>Só encontrar sua próxima palavra.</p></div></div></div>
    <div class="simulation"><span><strong>Experimente o tempo</strong> · antecipe uma troca sem esperar.</span><button class="btn" data-action="advance">Avançar ${formatInterval(state.interval)} →</button><button class="btn" data-action="pause">${state.pausedAt===null?'Pausar':'Retomar'}</button>${offset?'<button class="btn" data-action="reset-clock">Voltar ao relógio real</button>':''}</div>`;
}
function library(){
  let list=words;
  if(libraryFilter==='favorites')list=list.filter(w=>favorite(w.id));
  if(libraryFilter==='history')list=state.history.map(h=>words.find(w=>w.id===h.id)).filter((w,i,a)=>w&&a.findIndex(x=>x.id===w.id)===i);
  if(query){const q=query.normalize('NFD').replace(/\p{Diacritic}/gu,'').toLowerCase();list=list.filter(w=>[w.japanese,w.kana,w.romaji,w.meaning].join(' ').normalize('NFD').replace(/\p{Diacritic}/gu,'').toLowerCase().includes(q));}
  return `${header('Palavras que ficam.','SUA PEQUENA BIBLIOTECA',`${words.length} palavras, muitos começos. Encontre, salve e revisite.`)}<div class="toolbar"><input id="search" type="search" placeholder="Japonês, leitura ou português" aria-label="Buscar palavras" value="${esc(query)}"><select id="library-filter" aria-label="Filtrar palavras"><option value="all" ${libraryFilter==='all'?'selected':''}>Todas as palavras</option><option value="favorites" ${libraryFilter==='favorites'?'selected':''}>Palavras salvas</option><option value="history" ${libraryFilter==='history'?'selected':''}>Histórico de estudo</option></select></div><div class="word-list">${list.map(w=>`<button class="card word-row" data-action="open" data-id="${w.id}"><span class="jp" lang="ja">${esc(w.japanese)}</span><span>${state.showMeaning?`<span class="row-meaning">${esc(w.meaning)}</span>`:''}${state.showKana?`<span class="row-kana" lang="ja" style="display:block">${esc(w.kana)}</span>`:''}</span><span class="star" aria-label="${favorite(w.id)?'Salva':'Abrir palavra'}">${favorite(w.id)?'▣':'↗'}</span></button>`).join('')||'<div class="empty">Nenhuma palavra por aqui ainda.</div>'}</div>`;
}
function review(){const due=dueWords(),w=due[0];return `${header('Lembrar é aprender.','UM REENCONTRO COM O QUE VOCÊ JÁ VIU','Tente recuperar o significado antes de revelar a resposta.')}<div class="review-area">${w?`<div class="card flashcard"><span class="eyebrow">${due.length} ${due.length===1?'REVISÃO':'REVISÕES'} PARA AGORA</span><h2 class="japanese" lang="ja" style="margin:30px 0 18px">${esc(w.japanese)}</h2><button class="btn" data-action="speak" data-id="${w.id}">♫ Ouvir pronúncia</button>${revealed?`<p class="kana" lang="ja" style="margin-top:24px">${esc(w.kana)}</p><p class="meaning">${esc(w.meaning)}</p><p class="note">${esc(w.note)}</p><p class="note" lang="ja">${esc(w.example)}</p><p class="note">${esc(w.exampleMeaning)}</p>`:'<button class="btn primary" data-action="reveal" style="margin-top:28px">Revelar resposta ↗</button>'}</div>${revealed?`<p class="subtitle" style="text-align:center;margin-top:22px">Como foi lembrar?</p><div class="ratings">${[['again','Novamente','10 min'],['hard','Difícil','mais cedo'],['good','Bom','no seu ritmo'],['easy','Fácil','mais tarde']].map(([key,label,detail])=>`<button data-rating="${key}" data-id="${w.id}">${label}<small style="display:block;opacity:.6;margin-top:5px">${detail}</small></button>`).join('')}</div>`:''}`:'<div class="card empty"><div style="font-size:42px;color:var(--accent)">✳</div><h2 style="font:28px Georgia,serif">Por hoje, tudo em dia.</h2><p class="subtitle">As próximas revisões aparecem no momento certo.<br>Abra uma palavra para acrescentá-la à sua prática.</p><a class="btn primary" href="#words" style="margin-top:20px">Explorar palavras →</a></div>'}<p class="note" style="text-align:center">Repetição espaçada simples, com progresso salvo neste navegador.</p></div>`;}
const checked=value=>value?'checked':'';
function settings(){return `${header('Encontre o seu ritmo.','CADA PESSOA, UM TEMPO','Poucos minutos. Pequenos encontros. Um hábito que cabe no dia.')}<form id="settings-form"><div class="settings-grid"><section class="card settings-section"><h2>Uma palavra de cada vez.</h2><p class="setting-description">O ritmo das trocas é independente dos avisos.</p><label class="setting-row column">Trocar palavra<select name="interval" id="interval-choice">${presets.map(m=>`<option value="${m}" ${state.interval===m?'selected':''}>A cada ${formatInterval(m)}</option>`).join('')}<option value="custom" ${!presets.includes(state.interval)?'selected':''}>Intervalo personalizado</option></select></label><label class="setting-row" id="custom-row" ${presets.includes(state.interval)?'hidden':''}>Intervalo em minutos<input name="custom" type="number" min="1" max="10080" value="${state.interval}" style="width:100px"></label><p class="setting-description">No app nativo, o intervalo personalizado também pode ser informado em horas.</p><div class="setting-row"><span>Dias de estudo</span></div><div class="days">${['Dom','Seg','Ter','Qua','Qui','Sex','Sáb'].map((d,i)=>`<label>${d}<input type="checkbox" name="weekday" value="${i}" ${checked(state.weekdays.includes(i))} aria-label="Estudar ${d}"></label>`).join('')}</div><p class="setting-description">Dias desmarcados congelam as trocas. O cronograma considera o fuso deste navegador.</p><label class="setting-row">Pausar trocas<input class="switch" type="checkbox" name="paused" ${checked(state.pausedAt!==null)}></label></section>
    <section class="card settings-section"><h2>Um lembrete gentil.</h2><p class="setting-description">Nesta prévia, os avisos são apenas simulados. Notificações locais reais são uma função do projeto iOS.</p><label class="setting-row">Ativar avisos simulados<input class="switch" type="checkbox" name="notifications" ${checked(state.notifications)}></label><label class="setting-row column">Frequência de avisos<select name="notificationInterval">${[...new Set([...presets,state.notificationInterval])].sort((a,b)=>a-b).map(m=>`<option value="${m}" ${state.notificationInterval===m?'selected':''}>A cada ${formatInterval(m)}</option>`).join('')}</select></label><label class="setting-row">Silêncio a partir de<input type="time" name="quietStart" value="${String(state.quietStart).padStart(2,'0')}:00"></label><label class="setting-row">Voltar a avisar às<input type="time" name="quietEnd" value="${String(state.quietEnd).padStart(2,'0')}:00"></label><button type="button" class="btn" data-action="test-notification" style="margin-top:22px">Experimentar aviso simulado</button><p class="setting-description">No iOS, a fila tem até 60 avisos e é renovada ao reabrir o app. Não há execução contínua em segundo plano.</p></section>
    <section class="card settings-section"><h2>Do seu jeito.</h2><label class="setting-row">Mostrar hiragana<input class="switch" type="checkbox" name="showKana" ${checked(state.showKana)}></label><label class="setting-row">Mostrar romaji<input class="switch" type="checkbox" name="showRomaji" ${checked(state.showRomaji)}></label><label class="setting-row">Mostrar traduções<input class="switch" type="checkbox" name="showMeaning" ${checked(state.showMeaning)}></label><label class="setting-row">Modo escuro<input class="switch" type="checkbox" name="dark" ${checked(state.dark)}></label><p class="setting-description">As respostas dos flashcards continuam disponíveis ao revelar o verso. O layout respeita a preferência de movimento reduzido.</p></section>
    <section class="card settings-section"><h2>Na sua tela.</h2><p class="setting-description">Os widgets nativos compartilham o cronograma do app. O iOS decide quando atualizar sua aparência, e pode haver atrasos mesmo nos intervalos de 10 ou 20 minutos.</p><p class="setting-description">O projeto inclui widgets pequenos, médios, grandes e para a tela bloqueada. A miniatura desta prévia demonstra o design.</p><a href="https://github.com/joaocorrea-12/kotoba-japones" class="text-link" target="_blank" rel="noopener noreferrer">Acompanhar código e testes no GitHub ↗</a></section></div><div class="settings-bottom"><button class="btn primary" type="submit">Salvar meu ritmo →</button><span>Suas escolhas ficam salvas neste navegador.</span></div></form>`;}
function render(){
  if(!words.length)return;
  document.documentElement.classList.toggle('dark',state.dark);
  const page=route();document.querySelectorAll('[data-route]').forEach(a=>{a.classList.toggle('active',a.dataset.route===page);if(a.dataset.route===page)a.setAttribute('aria-current','page');else a.removeAttribute('aria-current');});
  main.innerHTML=page==='words'?library():page==='review'?review():page==='settings'?settings():today();currentID=current().id;
}
function showWord(id){const word=words.find(w=>w.id===id);if(!word)return;markSeen(word);document.querySelector('#dialog-content').innerHTML=wordCard(word,'NA SUA BIBLIOTECA');dialog.showModal();}
document.querySelector('.close').addEventListener('click',()=>dialog.close());
document.addEventListener('click',event=>{
  const button=event.target.closest('button');if(!button)return;
  if(button.dataset.size){widgetSize=button.dataset.size;render();return;}
  const id=button.dataset.id,word=words.find(w=>w.id===id);
  if(button.dataset.rating){state.reviews[id]=rate(state.reviews[id],button.dataset.rating,now());save();revealed=false;render();toast('Revisão salva. Um passo a mais.');return;}
  switch(button.dataset.action){
    case 'speak':speech(word);break;
    case 'favorite':state.favorites=favorite(id)?state.favorites.filter(x=>x!==id):[...state.favorites,id];save();render();if(dialog.open)document.querySelector('#dialog-content').innerHTML=wordCard(word,'NA SUA BIBLIOTECA');toast(favorite(id)?'Palavra guardada para outro encontro.':'Palavra removida das salvas.');break;
    case 'open':showWord(id);break;
    case 'reveal':revealed=true;render();break;
    case 'advance':if(state.pausedAt!==null){toast('Retome as trocas para experimentar o tempo.');return;}offset=Math.max(offset,(nextChange(state,now())??now())-Date.now()+50);render();toast('Relógio simulado: a próxima palavra chegou.');break;
    case 'pause':togglePause(state,now());save();render();break;
    case 'reset-clock':offset=0;render();toast('Relógio real restaurado.');break;
    case 'test-notification':toast(`Simulação · ${current().japanese}${state.showMeaning?' — '+current().meaning:''}`);break;
  }
});
document.addEventListener('input',event=>{if(event.target.id==='search'){const start=event.target.selectionStart;query=event.target.value;render();const input=document.querySelector('#search');input.focus();input.setSelectionRange(start,start);}});
document.addEventListener('change',event=>{
  if(event.target.id==='library-filter'){libraryFilter=event.target.value;render();}
  if(event.target.id==='interval-choice')document.querySelector('#custom-row').hidden=event.target.value!=='custom';
});
document.addEventListener('submit',event=>{
  if(event.target.id!=='settings-form')return;event.preventDefault();const form=new FormData(event.target);
  const minutes=Number(form.get('interval')==='custom'?form.get('custom'):form.get('interval'));
  const weekdays=form.getAll('weekday').map(Number);
  if(!weekdays.length){toast('Escolha pelo menos um dia de estudo.');return;}
  if(!Number.isInteger(minutes)||minutes<1||minutes>10080){toast('Escolha um intervalo de 1 minuto a 7 dias.');return;}
  const quietStart=Number(String(form.get('quietStart')).split(':')[0]),quietEnd=Number(String(form.get('quietEnd')).split(':')[0]);
  if(quietStart===quietEnd){toast('Escolha horários diferentes para o início e o fim do silêncio.');return;}
  if(minutes!==state.interval||String(weekdays)!==String(state.weekdays))changeInterval(state,minutes,now());
  state.weekdays=weekdays;state.notificationInterval=Number(form.get('notificationInterval'));state.quietStart=quietStart;state.quietEnd=quietEnd;
  for(const key of ['showKana','showRomaji','showMeaning','dark','notifications'])state[key]=form.has(key);
  if(form.has('paused')!==(state.pausedAt!==null))togglePause(state,now());
  save();render();toast('Seu ritmo foi salvo. Tudo no seu tempo.');
});
window.addEventListener('hashchange',()=>{revealed=false;render();window.scrollTo({top:0,behavior:'instant'});main.focus({preventScroll:true});});
document.addEventListener('visibilitychange',()=>{if(!document.hidden)render();});
setInterval(()=>{
  if(!words.length||document.hidden)return;
  if(current().id!==currentID){if(route()!=='settings')render();else currentID=current().id;}
  if(route()==='today'){const label=document.querySelector('[data-next]'),next=nextChange(state,now());if(label&&next)label.textContent=dateTime(next);}
},1000);
main.innerHTML='<div class="loading">Preparando seu encontro com o japonês…</div>';
try{const response=await fetch('./words.json');if(!response.ok)throw new Error();words=await response.json();render();}
catch{main.innerHTML='<div class="card empty"><h1>Não foi possível carregar as palavras.</h1><p>Abra a prévia por um servidor HTTP ou pelo endereço publicado. Os dados ficam incluídos no projeto.</p></div>';}
