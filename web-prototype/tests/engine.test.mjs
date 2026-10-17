import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {initialState,wordAt,nextChange,changeInterval,slot,togglePause,rate,activeSeconds,stableHash,presets} from '../dist/engine.mjs';

process.env.TZ='UTC';
const anchor=Date.parse('2026-10-16T12:00:00Z');
const words=[{id:'a'},{id:'b'},{id:'c'}];
test('Todos os intervalos predefinidos e personalizado respeitam a fronteira exata',()=>{
  for(const minutes of [...presets,1,73,10080]){
    const s=initialState(anchor);changeInterval(s,minutes,anchor);
    assert.equal(wordAt(s,words,anchor+minutes*60000-1).id,'a');
    assert.equal(wordAt(s,words,anchor+minutes*60000).id,'b');
    assert.equal(nextChange(s,anchor),anchor+minutes*60000);
  }
});
test('Um snapshot restaurado preserva a palavra após 99 dias sem execução',()=>{
  const s=initialState(anchor), restored=JSON.parse(JSON.stringify(s));
  assert.deepEqual(wordAt(s,words,anchor+99*86400000+123456),wordAt(restored,words,anchor+99*86400000+123456));
});
test('A pausa preserva os minutos restantes',()=>{
  const s=initialState(anchor);changeInterval(s,10,anchor);
  togglePause(s,anchor+300000);assert.equal(nextChange(s,anchor+900000),null);
  assert.equal(wordAt(s,words,anchor+3900000).id,'a');
  togglePause(s,anchor+3900000);assert.equal(nextChange(s,anchor+3900000),anchor+4200000);
});
test('Fim de semana congela e adia a troca para segunda-feira',()=>{
  const s=initialState(anchor);s.weekdays=[1,2,3,4,5];
  const saturday=Date.parse('2026-10-17T00:00:00Z'), monday=Date.parse('2026-10-19T00:00:00Z');
  assert.equal(slot(s,saturday),11);assert.equal(nextChange(s,saturday),monday);assert.equal(slot(s,monday),12);
});
test('Pausa atravessando o fim de semana conta apenas tempo ativo',()=>{
  const s=initialState(anchor);s.weekdays=[1,2,3,4,5];
  togglePause(s,Date.parse('2026-10-16T23:30:00Z'));togglePause(s,Date.parse('2026-10-19T00:30:00Z'));
  assert.equal(nextChange(s,Date.parse('2026-10-19T00:30:00Z')),Date.parse('2026-10-19T01:00:00Z'));
});
test('Alterar o intervalo preserva a palavra vigente',()=>{
  const s=initialState(anchor), later=anchor+3600000;
  assert.equal(wordAt(s,words,later).id,'b');changeInterval(s,20,later);
  assert.equal(wordAt(s,words,later).id,'b');assert.equal(wordAt(s,words,later+1200000).id,'c');
});
test('Intervalos inválidos são rejeitados',()=>{
  for(const value of [0,-1,10081,NaN,Infinity,1.5])assert.throws(()=>changeInterval(initialState(anchor),value,anchor));
});
test('Tempo anterior à âncora não produz índice negativo',()=>{
  assert.equal(slot(initialState(anchor),anchor-100000),0);
});
test('Vozes, favoritos e histórico não são necessários para calcular a palavra',()=>{
  const s=initialState(anchor), later=anchor+500000000;
  const expected=wordAt(s,words,later);s.favorites=['b'];s.history=[{id:'c',time:later}];
  assert.deepEqual(wordAt(s,words,later),expected);
});
test('Avisos e trocas têm intervalos independentes',()=>{
  const s=initialState(anchor);s.notificationInterval=720;changeInterval(s,10,anchor);
  assert.equal(s.notificationInterval,720);assert.equal(slot(s,anchor+3600000),6);
});
test('Revisão progride de um dia para três dias e permite reaprendizado',()=>{
  let r=rate(null,'good',anchor);assert.equal(r.interval,1);
  r=rate(r,'good',r.due);assert.equal(r.interval,3);
  for(let i=0;i<4;i++)r=rate(r,'good',r.due);
  assert.ok(r.successes>=5&&r.interval>=21);
  r=rate(r,'again',anchor);assert.equal(r.due,anchor+600000);assert.equal(r.successes,0);assert.equal(r.lapses,1);
});
test('Revisão respeita limites de facilidade e intervalo',()=>{
  let r;for(let i=0;i<50;i++)r=rate(r,'hard',anchor);assert.equal(r.ease,1.3);
  for(let i=0;i<50;i++)r=rate(r,'easy',anchor);assert.equal(r.ease,3);assert.equal(r.interval,365);
});
test('Hash FNV-1a coincide com o vetor usado nos testes Swift',()=>assert.equal(stableHash('kotoba'),9766424910215455371n));
test('Base de palavras é completa e identifica cada entrada de forma única',()=>{
  const items=JSON.parse(readFileSync(new URL('../dist/words.json',import.meta.url),'utf8'));
  assert.ok(items.length>=100);assert.equal(new Set(items.map(w=>w.id)).size,items.length);
  for(const word of items)for(const key of ['japanese','kana','romaji','meaning','partOfSpeech','example','exampleMeaning','note'])assert.ok(word[key]?.trim(),`${word.id}: ${key}`);
});
test('O relógio conta duração real, não apenas datas',()=>assert.equal(activeSeconds(initialState(anchor),anchor,anchor+1234000),1234));
