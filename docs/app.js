"use strict";

/* ============================================================
   QuickCompare HK — dependency-free price comparison app.

   Data source: data/index.json (written by the refresh agent).
   When the page is opened from file://, fetch() is blocked, so
   the page falls back to a small embedded sample below.
   ============================================================ */

const VIEWS = ["home", "browse", "deals", "compare", "alerts", "profile"];
const PAGE_SIZE = 48;
const DEAL_PAGE_SIZE = 24;
const COMPARE_PAGE_SIZE = 16;

const STORE_META = {
  wellcome: { letter: "W", color: "#e04b3a" },
  pns: { letter: "P", color: "#c8102e" },
  marketplace: { letter: "M", color: "#0e7c6b" },
  parknshop: { letter: "P", color: "#c8102e" },
  hktvmall: { letter: "H", color: "#e2231a" },
  aeon: { letter: "A", color: "#b02a86" },
  uselect: { letter: "U", color: "#2f6f4f" },
  citysuper: { letter: "C", color: "#0b6a8f" },
  fusion: { letter: "F", color: "#7a4bb5" },
  taste: { letter: "T", color: "#a86a13" },
  "759store": { letter: "7", color: "#e04b3a" },
  dondondonki: { letter: "D", color: "#2c5f9e" },
  yata: { letter: "Y", color: "#d64545" },
  sogo: { letter: "S", color: "#8a3b5c" },
  jhceshop: { letter: "J", color: "#2f6f4f" },
  dchfoodmart: { letter: "D", color: "#0b6a8f" }
};

const FALLBACK_COLORS = [
  "#017d70",
  "#c8102e",
  "#e04b3a",
  "#2f6f4f",
  "#7a4bb5",
  "#a86a13",
  "#0b6a8f",
  "#8a3b5c"
];

/* Curated staples for the "Trending in Hong Kong" rail. */
const TRENDING_DEFS = [
  { label: "Milk", q: "milk", emoji: "\u{1F95B}" },
  {
    label: "Eggs",
    q: "egg",
    emoji: "\u{1F95A}",
    include: /\begg(s)?\b/i,
    exclude: /eggplant|egg roll|egg noodle|egg white|egg yolk/i
  },
  { label: "Bread", q: "bread", emoji: "\u{1F35E}" },
  { label: "Rice", q: "rice", emoji: "\u{1F35A}" },
  { label: "Noodles", q: "noodle", emoji: "\u{1F35C}" },
  {
    label: "Coffee",
    q: "coffee",
    emoji: "\u2615",
    exclude: /mug|cup|bar|mate|sugar|candy|biscuit|cookie|ice cream/i
  },
  {
    label: "Beer",
    q: "beer",
    emoji: "\u{1F37A}",
    exclude: /root beer|beer mix|ginger beer/i
  },
  { label: "Snacks", q: "snack", emoji: "\u{1F37F}" },
  { label: "Toothpaste", q: "toothpaste", emoji: "\u{1FAA5}" },
  { label: "Laundry", q: "laundry", emoji: "\u{1F9FA}" },
  { label: "Cat food", q: "cat food", emoji: "\u{1F431}" },
  { label: "Dog food", q: "dog food", emoji: "\u{1F436}" }
];

const PREFERRED_BRANDS = [
  "LEE KUM KEE",
  "NISSIN",
  "AMOY",
  "VITA",
  "NESTLE",
  "DETTOL",
  "COLGATE",
  "WATSONS",
  "KAI TSUN TONG",
  "CALBEE",
  "GARDEN",
  "WAITROSE",
  "SELECT",
  "INABA",
  "KAKATO"
];

const DISTRICTS = ["Hong Kong", "Hong Kong Island", "Kowloon", "New Territories"];

const EMBEDDED_INDEX = {
  generatedAt: null,
  currency: "HKD",
  sample: true,
  stores: [
    { id: "parknshop", name: "ParknShop", url: "https://www.parknshop.com/" },
    { id: "wellcome", name: "Wellcome", url: "https://www.wellcome.com.hk/" },
    { id: "aeon", name: "AEON", url: "https://www.aeon.com.hk/" },
    { id: "uselect", name: "U Select", url: "https://www.uselect.com.hk/" },
    { id: "hktvmall", name: "HKTVmall", url: "https://www.hktvmall.com/" },
    { id: "citysuper", name: "City'Super", url: "https://www.citysuper.com.hk/" },
    { id: "marketplace", name: "Market Place", url: "https://www.marketplacehk.com/" },
    { id: "759store", name: "759 Store", url: "https://www.759store.com/" },
    { id: "dondondonki", name: "Don Don Donki", url: "https://www.dondondonki.com/hk/" }
  ],
  products: [
    { store: "parknshop", storeName: "ParknShop", sku: "SAMPLE-001", name: "Nissin Demae Ramen Sesame Oil 5 x 100g", brand: "Nissin", barcode: "4890000000011", category: ["Instant Noodles", "Noodles"], size: "5 x 100g", price: 24.9, originalPrice: 29.9, currency: "HKD", unitPrice: 4.98, unit: "per 100g", inStock: true, promotion: "Buy 2 get 10% off", image: null, url: "https://www.parknshop.com/", linkType: "search", lastSeen: "2026-11-07T09:00:00+08:00", lastChecked: "2026-11-07T09:00:00+08:00" },
    { store: "wellcome", storeName: "Wellcome", sku: "SAMPLE-002", name: "Nissin Demae Ramen Sesame Oil 5 x 100g", brand: "Nissin", barcode: "4890000000011", category: ["Instant Noodles", "Noodles"], size: "5 x 100g", price: 26.5, originalPrice: null, currency: "HKD", unitPrice: 5.3, unit: "per 100g", inStock: true, promotion: null, image: null, url: "https://www.wellcome.com.hk/", linkType: "search", lastSeen: "2026-11-07T09:00:00+08:00", lastChecked: "2026-11-07T09:00:00+08:00" },
    { store: "hktvmall", storeName: "HKTVmall", sku: "SAMPLE-003", name: "Vita Lemon Tea 250ml x 6", brand: "Vita", barcode: "4890000000028", category: ["Beverages", "Tea"], size: "6 x 250ml", price: 19.9, originalPrice: 25.9, currency: "HKD", unitPrice: 3.32, unit: "per 250ml", inStock: true, promotion: "Flash sale", image: null, url: "https://www.hktvmall.com/", linkType: "search", lastSeen: "2026-11-07T09:00:00+08:00", lastChecked: "2026-11-07T09:00:00+08:00" },
    { store: "parknshop", storeName: "ParknShop", sku: "SAMPLE-004", name: "Vita Lemon Tea 250ml x 6", brand: "Vita", barcode: "4890000000028", category: ["Beverages", "Tea"], size: "6 x 250ml", price: 21.9, originalPrice: null, currency: "HKD", unitPrice: 3.65, unit: "per 250ml", inStock: true, promotion: null, image: null, url: "https://www.parknshop.com/", linkType: "search", lastSeen: "2026-11-07T09:00:00+08:00", lastChecked: "2026-11-07T09:00:00+08:00" },
    { store: "wellcome", storeName: "Wellcome", sku: "SAMPLE-005", name: "Kowloon Dairy Fresh Milk 946ml", brand: "Kowloon Dairy", barcode: "4890000000035", category: ["Dairy", "Milk"], size: "946ml", price: 28, originalPrice: null, currency: "HKD", unitPrice: 2.96, unit: "per 100ml", inStock: true, promotion: null, image: null, url: "https://www.wellcome.com.hk/", linkType: "search", lastSeen: "2026-11-07T09:00:00+08:00", lastChecked: "2026-11-07T09:00:00+08:00" },
    { store: "aeon", storeName: "AEON", sku: "SAMPLE-006", name: "Kowloon Dairy Fresh Milk 946ml", brand: "Kowloon Dairy", barcode: "4890000000035", category: ["Dairy", "Milk"], size: "946ml", price: 26.5, originalPrice: 29, currency: "HKD", unitPrice: 2.8, unit: "per 100ml", inStock: true, promotion: "Member price", image: null, url: "https://www.aeon.com.hk/", linkType: "search", lastSeen: "2026-11-07T09:00:00+08:00", lastChecked: "2026-11-07T09:00:00+08:00" },
    { store: "parknshop", storeName: "ParknShop", sku: "SAMPLE-007", name: "Lee Kum Kee Premium Soy Sauce 500ml", brand: "Lee Kum Kee", barcode: "4890000000042", category: ["Condiments", "Sauce"], size: "500ml", price: 38.9, originalPrice: null, currency: "HKD", unitPrice: 7.78, unit: "per 100ml", inStock: true, promotion: null, image: null, url: "https://www.parknshop.com/", linkType: "search", lastSeen: "2026-11-07T09:00:00+08:00", lastChecked: "2026-11-07T09:00:00+08:00" },
    { store: "uselect", storeName: "U Select", sku: "SAMPLE-008", name: "Lee Kum Kee Premium Soy Sauce 500ml", brand: "Lee Kum Kee", barcode: "4890000000042", category: ["Condiments", "Sauce"], size: "500ml", price: 36, originalPrice: 39.9, currency: "HKD", unitPrice: 7.2, unit: "per 100ml", inStock: false, promotion: null, image: null, url: "https://www.uselect.com.hk/", linkType: "search", lastSeen: "2026-11-07T09:00:00+08:00", lastChecked: "2026-11-07T09:00:00+08:00" },
    { store: "wellcome", storeName: "Wellcome", sku: "SAMPLE-009", name: "Amoy Golden Label Jasmine Rice 8kg", brand: "Amoy", barcode: "4890000000059", category: ["Rice", "Pantry"], size: "8kg", price: 89, originalPrice: 99, currency: "HKD", unitPrice: 11.13, unit: "per kg", inStock: true, promotion: null, image: null, url: "https://www.wellcome.com.hk/", linkType: "search", lastSeen: "2026-11-07T09:00:00+08:00", lastChecked: "2026-11-07T09:00:00+08:00" },
    { store: "hktvmall", storeName: "HKTVmall", sku: "SAMPLE-010", name: "Amoy Golden Label Jasmine Rice 8kg", brand: "Amoy", barcode: "4890000000059", category: ["Rice", "Pantry"], size: "8kg", price: 85, originalPrice: null, currency: "HKD", unitPrice: 10.63, unit: "per kg", inStock: true, promotion: null, image: null, url: "https://www.hktvmall.com/", linkType: "search", lastSeen: "2026-11-07T09:00:00+08:00", lastChecked: "2026-11-07T09:00:00+08:00" },
    { store: "759store", storeName: "759 Store", sku: "SAMPLE-011", name: "Haagen-Dazs Vanilla Ice Cream 100ml", brand: "Haagen-Dazs", barcode: "4890000000066", category: ["Frozen", "Ice Cream"], size: "100ml", price: 19.9, originalPrice: 24.9, currency: "HKD", unitPrice: 19.9, unit: "per 100ml", inStock: true, promotion: null, image: null, url: "https://www.759store.com/", linkType: "search", lastSeen: "2026-11-07T09:00:00+08:00", lastChecked: "2026-11-07T09:00:00+08:00" },
    { store: "dondondonki", storeName: "Don Don Donki", sku: "SAMPLE-012", name: "Meiji Oishii Fresh Milk 946ml", brand: "Meiji", barcode: "4890000000073", category: ["Dairy", "Milk"], size: "946ml", price: 32, originalPrice: null, currency: "HKD", unitPrice: 3.38, unit: "per 100ml", inStock: true, promotion: null, image: null, url: "https://www.dondondonki.com/hk/", linkType: "search", lastSeen: "2026-11-07T09:00:00+08:00", lastChecked: "2026-11-07T09:00:00+08:00" }
  ]
};

const state = {
  view: "home",
  q: "",
  store: "all",
  category: "all",
  sort: "relevance",
  inStock: false,
  dealSort: "discount",
  listLimit: PAGE_SIZE,
  dealLimit: DEAL_PAGE_SIZE,
  compareLimit: COMPARE_PAGE_SIZE,
  district: "Hong Kong",
  theme: "system"
};

let INDEX = null;
let STATS = null;
let DEALS = [];
let TRENDING = [];
let BRANDS = [];
let ALERTS = [];
let RECENT = [];
let suggestItems = [];
let suggestIndex = -1;
let searchTimer = null;
let toastTimer = null;

const $ = (id) => document.getElementById(id);
const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];

const moneyFmt = new Intl.NumberFormat("en-HK", {
  minimumFractionDigits: 2,
  maximumFractionDigits: 2
});
const countFmt = new Intl.NumberFormat("en-HK");

/* ============================================================
   Helpers
   ============================================================ */

function esc(value) {
  return String(value == null ? "" : value).replace(/[&<>"']/g, (ch) => ({
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': "&quot;",
    "'": "&#39;"
  }[ch]));
}

function money(value) {
  const n = Number(value);
  return value == null || Number.isNaN(n) ? "\u2014" : "HK$" + moneyFmt.format(n);
}

function moneyRound(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return "\u2014";
  return "HK$" + Math.round(n).toLocaleString("en-HK");
}

function fmt(value) {
  return countFmt.format(Number(value) || 0);
}

function norm(value) {
  return String(value == null ? "" : value)
    .toLowerCase()
    .replace(/[^a-z0-9\u4e00-\u9fff]+/g, " ")
    .trim();
}

function formatTime(iso) {
  if (!iso) return "not yet refreshed";
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return String(iso);
  return date.toLocaleString("en-HK", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
    timeZone: "Asia/Hong_Kong"
  });
}

function timeAgo(iso) {
  if (!iso) return "never";
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return "unknown";
  const diff = Date.now() - date.getTime();
  if (diff < 0) return "just now";
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return "just now";
  if (mins < 60) return mins + " min ago";
  const hours = Math.floor(mins / 60);
  if (hours < 24) return hours + " hr ago";
  const days = Math.floor(hours / 24);
  if (days === 1) return "yesterday";
  if (days < 30) return days + " days ago";
  return formatTime(iso);
}

function storeMeta(id, name) {
  if (STORE_META[id]) return STORE_META[id];
  const label = String(name || id || "S");
  let hash = 0;
  for (let i = 0; i < label.length; i++) hash = (hash * 31 + label.charCodeAt(i)) >>> 0;
  return {
    letter: label.charAt(0).toUpperCase(),
    color: FALLBACK_COLORS[hash % FALLBACK_COLORS.length]
  };
}

function initialOf(value) {
  const text = String(value || "?").replace(/^[^a-z0-9\u4e00-\u9fff]+/i, "");
  return (text.charAt(0) || "?").toUpperCase();
}

function productUrl(product) {
  if (product && product.url) return product.url;
  const store = (INDEX.stores || []).find((s) => s.id === product.store);
  return store ? store.url : "#";
}

function productBrandLine(product) {
  const bits = [];
  if (product.brand) bits.push(product.brand);
  if (product.size) bits.push(product.size);
  if (!bits.length && Array.isArray(product.category) && product.category.length) {
    bits.push(product.category[0]);
  }
  return bits.join(" \u00b7 ");
}

function discountPct(product) {
  const price = Number(product.price);
  const original = Number(product.originalPrice);
  if (!Number.isFinite(price) || !Number.isFinite(original) || original <= price || price <= 0) {
    return 0;
  }
  return Math.max(0, Math.round((1 - price / original) * 100));
}

function savingAmount(product) {
  const price = Number(product.price);
  const original = Number(product.originalPrice);
  if (!Number.isFinite(price) || !Number.isFinite(original) || original <= price) return 0;
  return original - price;
}

function readLS(key, fallback) {
  try {
    const raw = localStorage.getItem(key);
    if (!raw) return fallback;
    return JSON.parse(raw);
  } catch (error) {
    return fallback;
  }
}

function writeLS(key, value) {
  try {
    localStorage.setItem(key, JSON.stringify(value));
  } catch (error) {
    /* Storage can be unavailable in private mode; the page still works. */
  }
}

function removeLS(key) {
  try {
    localStorage.removeItem(key);
  } catch (error) {}
}

function toast(message) {
  const el = $("toast");
  if (!el) return;
  el.textContent = message;
  el.hidden = false;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => {
    el.hidden = true;
  }, 2800);
}

/* ============================================================
   Data
   ============================================================ */

async function loadIndex() {
  try {
    const response = await fetch("data/index.json", { cache: "no-cache" });
    if (!response.ok) throw new Error("HTTP " + response.status);
    const data = await response.json();
    if (!data || !Array.isArray(data.products)) throw new Error("bad shape");
    return data;
  } catch (error) {
    console.warn("Using embedded sample index:", error.message);
    return EMBEDDED_INDEX;
  }
}

function buildDerived() {
  const storeCounts = Object.create(null);
  const storeLast = Object.create(null);
  const catCounts = new Map();
  const brandCounts = new Map();
  const deals = [];

  for (const product of INDEX.products) {
    if (!product || typeof product !== "object") continue;

    storeCounts[product.store] = (storeCounts[product.store] || 0) + 1;

    const checked = product.lastChecked || product.lastSeen;
    if (checked && (!storeLast[product.store] || checked > storeLast[product.store])) {
      storeLast[product.store] = checked;
    }

    for (const category of product.category || []) {
      catCounts.set(category, (catCounts.get(category) || 0) + 1);
    }

    const brand = String(product.brand || "").trim();
    if (brand) brandCounts.set(brand, (brandCounts.get(brand) || 0) + 1);

    if (discountPct(product) >= 5) deals.push(product);
  }

  deals.sort((a, b) => {
    const diff = discountPct(b) - discountPct(a);
    return diff !== 0 ? diff : savingAmount(b) - savingAmount(a);
  });

  STATS = {
    storeCounts,
    storeLast,
    catCounts,
    brandCounts,
    totals: {
      products: INDEX.products.length,
      stores: (INDEX.stores || []).length,
      categories: catCounts.size,
      deals: deals.length
    }
  };

  DEALS = deals;
  TRENDING = buildTrending();
  BRANDS = buildBrands();
}

function buildTrending() {
  const tracked = TRENDING_DEFS.map((def) => ({
    label: def.label,
    q: def.q,
    emoji: def.emoji,
    include: def.include || null,
    exclude: def.exclude || null,
    terms: norm(def.q).split(" ").filter(Boolean),
    count: 0,
    image: null,
    imageStore: null,
    bestName: null
  }));

  for (const product of INDEX.products) {
    const name = String(product.name || "").toLowerCase();
    const brand = String(product.brand || "").toLowerCase();
    const categories = Array.isArray(product.category)
      ? product.category.join(" ").toLowerCase()
      : "";
    const haystack = name + " " + brand + " " + categories;

    for (const item of tracked) {
      const matches = item.include
        ? item.include.test(name)
        : item.terms.every((term) => haystack.includes(term));
      if (!matches) continue;
      if (item.exclude && item.exclude.test(name)) continue;

      item.count++;

      /*
       * PNS blocks hotlinked images (HTTP 403), so prefer a product from a
       * store whose CDN is publicly readable. The emoji in the tile is the
       * fallback when no usable image exists.
       */
      if (product.image && product.store !== "pns") {
        if (!item.bestName || name.length < item.bestName.length) {
          item.image = product.image;
          item.imageStore = product.store;
          item.bestName = name;
        }
      }
    }
  }

  return tracked
    .filter((item) => item.count > 0)
    .map((item) => ({
      label: item.label,
      q: item.q,
      emoji: item.emoji,
      count: item.count,
      image: item.image
    }));
}

function buildBrands() {
  if (!STATS) return [];
  const byUpper = new Map();
  for (const [name, count] of STATS.brandCounts) {
    byUpper.set(name.toUpperCase(), { name, count });
  }

  const out = [];
  const seen = new Set();

  for (const preferred of PREFERRED_BRANDS) {
    const hit = byUpper.get(preferred);
    if (hit && !seen.has(preferred)) {
      seen.add(preferred);
      out.push(hit);
    }
  }

  const rest = [...byUpper.entries()]
    .filter(([upper]) => !seen.has(upper))
    .sort((a, b) => b[1].count - a[1].count);

  for (const [upper, item] of rest) {
    if (out.length >= 15) break;
    seen.add(upper);
    out.push(item);
  }

  return out;
}

/* ============================================================
   Global metadata + home
   ============================================================ */

function renderGlobalMeta() {
  if (!INDEX || !STATS) return;
  const total = STATS.totals.products;
  const stores = STATS.totals.stores;

  $("topMeta").textContent = fmt(total) + " products \u00b7 " + fmt(stores) + " stores";
  $("footerMeta").textContent = INDEX.sample
    ? "Sample index \u00b7 full catalogue not loaded"
    : fmt(total) + " products \u00b7 " + fmt(stores) + " stores \u00b7 index " + formatTime(INDEX.generatedAt);
  $("year").textContent = String(new Date().getFullYear());
}

function setupHero() {
  const total = STATS.totals.products;
  const top = DEALS.find((product) => product.image) || DEALS[0] || null;

  $("heroCount").textContent = fmt(total);
  $("statProducts").textContent = fmt(total);
  $("statStores").textContent = fmt(STATS.totals.stores);
  $("statDeals").textContent = fmt(STATS.totals.deals);
  $("heroDealCount").textContent = fmt(STATS.totals.deals);
  $("promoDealCount").textContent = fmt(STATS.totals.deals);
  $("floatStores").textContent = fmt(STATS.totals.stores);

  if (!top) {
    $("heroBadge").textContent = "Live";
    $("heroName").textContent = "No discounted products in the current index.";
    $("heroStore").textContent = "";
    $("heroPrice").textContent = "\u2014";
    $("heroWas").textContent = "";
    $("heroFoot").textContent = "Prices refreshed every 6 hours";
    $("floatSaving").textContent = "\u2014";
    $("promoPercent").textContent = "\u2014";
    return;
  }

  const pct = discountPct(top);
  const price = money(top.price);
  const was = top.originalPrice != null ? money(top.originalPrice) : "";

  $("heroBadge").textContent = pct > 0 ? "-" + pct + "%" : "Live";
  $("heroName").textContent = top.name || "Unnamed product";
  $("heroStore").textContent = (top.storeName || top.store) + (top.lastChecked ? " \u00b7 checked " + timeAgo(top.lastChecked) : "");
  $("heroPrice").textContent = price;
  $("heroWas").textContent = was;
  $("heroFoot").textContent = top.lastChecked
    ? "Last checked " + timeAgo(top.lastChecked)
    : "Prices refreshed every 6 hours";
  $("floatSaving").textContent = moneyRound(savingAmount(top));
  $("promoPercent").textContent = pct + "%";

  const thumb = $("heroThumb");
  thumb.className = "hero-thumb" + (top.image ? "" : " img-fail");
  thumb.innerHTML = top.image
    ? `<img src="${esc(top.image)}" alt="" loading="eager" decoding="async" onerror="this.style.display='none';this.parentElement.classList.add('img-fail')"><span class="thumb-fallback">${esc(initialOf(top.brand || top.name))}</span>`
    : `<span class="thumb-fallback">${esc(initialOf(top.brand || top.name))}</span>`;
}

function renderStores() {
  const stores = (INDEX.stores || []).slice().sort((a, b) => String(a.name).localeCompare(String(b.name)));
  const element = $("storeStrip");

  if (!stores.length) {
    element.innerHTML = '<p class="section-sub">No stores in the index.</p>';
    return;
  }

  element.innerHTML = stores.map((store) => {
    const meta = storeMeta(store.id, store.name);
    const count = STATS.storeCounts[store.id] || 0;
    const last = STATS.storeLast[store.id];
    return `
      <button class="store-card" type="button" data-store="${esc(store.id)}">
        <span class="store-avatar" style="background:${meta.color}">${esc(meta.letter)}</span>
        <span class="store-card-body">
          <span class="store-card-name">${esc(store.name)}</span>
          <span class="store-card-count">${fmt(count)} products</span>
          <span class="store-card-time">
            <svg class="icon"><use href="#i-check"/></svg>
            ${last ? "Checked " + esc(timeAgo(last)) : "Not checked yet"}
          </span>
        </span>
      </button>
    `;
  }).join("");

  $("storesSub").textContent = stores.length + " stores tracked \u00b7 last full refresh " + timeAgo(INDEX.generatedAt);
}

function renderTrending() {
  const element = $("trendingStrip");
  if (!TRENDING.length) {
    element.innerHTML = '<p class="section-sub">No trending products found.</p>';
    return;
  }

  element.innerHTML = TRENDING.map((item) => `
    <button class="trend-card" type="button" data-query="${esc(item.q)}">
      <span class="trend-img">
        <span class="trend-emoji" aria-hidden="true">${esc(item.emoji || "\u{1F6D2}")}</span>
        ${item.image ? `<img src="${esc(item.image)}" alt="" loading="lazy" decoding="async" onerror="this.style.display='none'">` : ""}
      </span>
      <span class="trend-name">${esc(item.label)}</span>
      <span class="trend-count">${fmt(item.count)} products</span>
    </button>
  `).join("");
}

function renderBrands() {
  const element = $("brandCloud");
  if (!BRANDS.length) {
    element.innerHTML = '<p class="section-sub">No brand data in the current index.</p>';
    return;
  }

  element.innerHTML = BRANDS.map((brand) => `
    <button class="brand-chip" type="button" data-query="${esc(brand.name)}">
      ${esc(brand.name)}
      <small>${fmt(brand.count)}</small>
    </button>
  `).join("");
}

function dealTile(product) {
  const meta = storeMeta(product.store, product.storeName);
  const pct = discountPct(product);
  const was = product.originalPrice != null ? money(product.originalPrice) : "";
  return `
    <a class="deal-tile" href="${esc(productUrl(product))}" target="_blank" rel="noopener noreferrer">
      <span class="deal-img${product.image ? "" : " img-fail"}">
        ${product.image ? `<img src="${esc(product.image)}" alt="" loading="lazy" decoding="async" onerror="this.style.display='none';this.parentElement.classList.add('img-fail')">` : ""}
        <span class="thumb-fallback">${esc(initialOf(product.brand || product.name))}</span>
        ${pct > 0 ? `<span class="discount-badge">-${pct}%</span>` : ""}
      </span>
      <span class="deal-name">${esc(product.name)}</span>
      <span class="deal-price-row">
        <span class="deal-price">${money(product.price)}</span>
        ${was ? `<span class="was">${was}</span>` : ""}
      </span>
      <span class="deal-store">
        <i class="mini-dot" style="background:${meta.color}"></i>
        ${esc(product.storeName || product.store)}
      </span>
    </a>
  `;
}

function renderDrops() {
  const element = $("dropStrip");
  const top = DEALS.slice(0, 12);
  if (!top.length) {
    element.innerHTML = '<p class="section-sub">No discounts in the current index.</p>';
    return;
  }
  element.innerHTML = top.map(dealTile).join("");
}

function renderHomeNotices() {
  const old = $("homeNotice");
  if (old) old.remove();

  const hero = document.querySelector("#view-home .hero");
  if (!hero) return;

  let notice = "";
  if (INDEX.sample) {
    notice = `
      <div class="info-strip">
        <span class="info-icon"><svg class="icon"><use href="#i-info"/></svg></span>
        <p><strong>Sample data.</strong> The browser could not fetch <code>data/index.json</code>, so this page is showing a small demo set. Serve the <code>site</code> folder over HTTP or run the refresh agent to load the full catalogue.</p>
      </div>
    `;
  } else {
    const generated = INDEX.generatedAt ? new Date(INDEX.generatedAt).getTime() : 0;
    const ageHours = generated ? (Date.now() - generated) / 3600000 : 0;
    if (generated && ageHours > 12) {
      notice = `
        <div class="info-strip">
          <span class="info-icon"><svg class="icon"><use href="#i-clock"/></svg></span>
          <p><strong>Index refreshed ${esc(timeAgo(INDEX.generatedAt))}.</strong> Prices and availability may have changed since then. Open the store page to confirm before buying.</p>
        </div>
      `;
    }
  }

  if (!notice) return;
  const holder = document.createElement("div");
  holder.className = "wrap";
  holder.id = "homeNotice";
  holder.style.marginTop = "22px";
  holder.innerHTML = notice;
  hero.insertAdjacentElement("afterend", holder);
}

function renderHome() {
  if (!INDEX || !STATS) return;
  setupHero();
  renderStores();
  renderTrending();
  renderBrands();
  renderDrops();
  renderHomeNotices();
  renderGlobalMeta();
}

/* ============================================================
   Browse / filters
   ============================================================ */

function buildFilters() {
  const storeSelect = $("store");
  while (storeSelect.options.length > 1) storeSelect.remove(1);

  const stores = (INDEX.stores || []).slice().sort((a, b) => String(a.name).localeCompare(String(b.name)));
  for (const store of stores) {
    const option = document.createElement("option");
    option.value = store.id;
    option.textContent = store.name;
    storeSelect.appendChild(option);
  }

  const categorySelect = $("category");
  while (categorySelect.options.length > 1) categorySelect.remove(1);

  const categories = STATS ? [...STATS.catCounts.keys()] : [];
  categories.sort((a, b) => a.localeCompare(b));
  for (const category of categories) {
    const option = document.createElement("option");
    option.value = category;
    option.textContent = category;
    categorySelect.appendChild(option);
  }
}

function syncFilters() {
  if ($("store")) $("store").value = state.store;
  if ($("category")) $("category").value = state.category;
  if ($("sort")) $("sort").value = state.sort;
  if ($("inStock")) $("inStock").checked = state.inStock;
  if ($("dealSort")) $("dealSort").value = state.dealSort;
}

function relevanceScore(product, query) {
  const name = norm(product.name);
  const brand = norm(product.brand);
  let score = 0;

  if (name === query) score += 130;
  else if (name.startsWith(query)) score += 85;
  else if (name.includes(query)) score += 45;
  else if (query.split(" ").every((term) => name.includes(term))) score += 25;

  if (brand === query) score += 100;
  else if (brand.startsWith(query)) score += 55;
  else if (brand.includes(query)) score += 30;

  if ((product.barcode || "").toLowerCase().includes(query)) score += 150;
  if (product.inStock !== false) score += 4;
  return score;
}

function byPriceAsc(a, b) {
  const av = a.price == null ? null : Number(a.price);
  const bv = b.price == null ? null : Number(b.price);
  if (av == null && bv == null) return 0;
  if (av == null) return 1;
  if (bv == null) return -1;
  return av - bv;
}

function byPriceDesc(a, b) {
  const av = a.price == null ? null : Number(a.price);
  const bv = b.price == null ? null : Number(b.price);
  if (av == null && bv == null) return 0;
  if (av == null) return 1;
  if (bv == null) return -1;
  return bv - av;
}

function byUnitAsc(a, b) {
  const av = a.unitPrice == null ? null : Number(a.unitPrice);
  const bv = b.unitPrice == null ? null : Number(b.unitPrice);
  if (av == null && bv == null) return 0;
  if (av == null) return 1;
  if (bv == null) return -1;
  return av - bv;
}

function filteredProducts(options = {}) {
  const ignoreStore = Boolean(options.ignoreStore);
  const query = norm(state.q);
  const terms = query ? query.split(" ").filter(Boolean) : [];
  const rows = [];
  const scores = query && state.sort === "relevance" ? new Map() : null;

  for (const product of INDEX.products) {
    if (!ignoreStore && state.store !== "all" && product.store !== state.store) continue;
    if (state.inStock && !product.inStock) continue;
    if (state.category !== "all" && !(product.category || []).includes(state.category)) continue;

    if (terms.length) {
      const haystack = norm([
        product.name,
        product.brand,
        product.barcode,
        product.size,
        product.storeName,
        Array.isArray(product.category) ? product.category.join(" ") : ""
      ].join(" "));
      if (!terms.every((term) => haystack.includes(term))) continue;
    }

    rows.push(product);
    if (scores) scores.set(product, relevanceScore(product, query));
  }

  switch (state.sort) {
    case "price-asc":
      rows.sort(byPriceAsc);
      break;
    case "price-desc":
      rows.sort(byPriceDesc);
      break;
    case "unit-asc":
      rows.sort(byUnitAsc);
      break;
    case "discount":
      rows.sort((a, b) => discountPct(b) - discountPct(a));
      break;
    case "name-asc":
      rows.sort((a, b) => String(a.name || "").localeCompare(String(b.name || "")));
      break;
    default:
      if (scores) {
        rows.sort((a, b) => (scores.get(b) || 0) - (scores.get(a) || 0));
      }
      break;
  }

  return rows;
}

function productCard(product) {
  const meta = storeMeta(product.store, product.storeName);
  const pct = discountPct(product);
  const was = product.originalPrice != null && Number(product.originalPrice) > Number(product.price)
    ? `<span class="was">${money(product.originalPrice)}</span>`
    : "";
  const unit = product.unitPrice != null
    ? `<span class="product-unit">${money(product.unitPrice)}${product.unit ? " " + esc(product.unit) : ""}</span>`
    : "";
  const promo = product.promotion
    ? `<span class="product-promo">${esc(product.promotion)}</span>`
    : "";
  const brandLine = productBrandLine(product);
  const url = productUrl(product);
  const linkLabel = product.linkType === "search" ? "Search store" : "Go to store";
  const stock = product.inStock !== false
    ? '<span class="stock-tag">In stock</span>'
    : '<span class="stock-tag out">Out of stock</span>';

  return `
    <article class="product-card">
      <a class="product-thumb${product.image ? "" : " img-fail"}" href="${esc(url)}" target="_blank" rel="noopener noreferrer" aria-label="${esc(product.name)} at ${esc(product.storeName || product.store)}">
        ${product.image ? `<img src="${esc(product.image)}" alt="" loading="lazy" decoding="async" onerror="this.style.display='none';this.parentElement.classList.add('img-fail')">` : ""}
        <span class="thumb-fallback">${esc(initialOf(product.brand || product.name))}</span>
        <span class="store-pill"><i class="mini-dot" style="background:${meta.color}"></i>${esc(product.storeName || product.store)}</span>
        ${pct > 0 ? `<span class="discount-badge">-${pct}%</span>` : ""}
      </a>
      <div class="product-body">
        <span class="product-brand">${esc(brandLine)}</span>
        <h3 class="product-name"><a href="${esc(url)}" target="_blank" rel="noopener noreferrer">${esc(product.name)}</a></h3>
        <div class="product-price-row">
          <span class="product-price">${money(product.price)}</span>
          ${was}
        </div>
        ${unit}
        ${promo}
        <div class="product-foot">
          ${stock}
          <span class="product-checked" title="${esc(formatTime(product.lastChecked))}">${esc(timeAgo(product.lastChecked))}</span>
        </div>
        <a class="product-go" href="${esc(url)}" target="_blank" rel="noopener noreferrer">
          ${esc(linkLabel)}
          <svg class="icon"><use href="#i-arrow"/></svg>
        </a>
      </div>
    </article>
  `;
}

function renderList() {
  if (!INDEX) return;
  const rows = filteredProducts();
  const shown = rows.slice(0, state.listLimit);
  const storeIds = new Set(rows.map((product) => product.store));

  $("results").innerHTML = shown.map(productCard).join("");
  $("empty").hidden = rows.length !== 0;
  $("more").hidden = shown.length >= rows.length;

  const countText = rows.length === 0
    ? "0 products"
    : "Showing " + fmt(shown.length) + " of " + fmt(rows.length) + " products";
  $("count").textContent = countText;

  const storeName = state.store !== "all"
    ? ((INDEX.stores || []).find((store) => store.id === state.store) || {}).name || state.store
    : "";

  let title = "All products";
  if (state.q.trim()) title = "Results for \u201c" + state.q.trim() + "\u201d";
  else if (state.category !== "all") title = state.category;
  else if (state.store !== "all") title = storeName;

  $("browseTitle").textContent = title;
  $("browseSub").textContent = rows.length
    ? fmt(rows.length) + " products from " + fmt(storeIds.size) + " stores match the current filters."
    : "No products match the current filters. Try a shorter phrase or reset the filters.";
  $("browseRefreshed").textContent = INDEX.sample
    ? "sample index"
    : "index updated " + formatTime(INDEX.generatedAt);

  renderActiveFilters();
  document.title = title + " \u2014 QuickCompare HK";
}

function activeFilterChips() {
  const chips = [];
  if (state.q.trim()) chips.push({ kind: "q", label: "\u201c" + state.q.trim() + "\u201d" });
  if (state.store !== "all") {
    const store = (INDEX.stores || []).find((item) => item.id === state.store);
    chips.push({ kind: "store", label: (store && store.name) || state.store });
  }
  if (state.category !== "all") chips.push({ kind: "category", label: state.category });
  if (state.inStock) chips.push({ kind: "inStock", label: "In stock only" });
  return chips;
}

function renderActiveFilters() {
  const element = $("activeFilters");
  const chips = activeFilterChips();
  if (!chips.length) {
    element.hidden = true;
    element.innerHTML = "";
    return;
  }

  element.hidden = false;
  element.innerHTML = chips.map((chip) => `
    <span class="filter-chip">
      ${esc(chip.label)}
      <button type="button" data-clear="${chip.kind}" aria-label="Remove ${esc(chip.label)} filter">
        <svg class="icon"><use href="#i-close"/></svg>
      </button>
    </span>
  `).join("") + '<button class="filter-reset" type="button" data-clear="all">Clear all</button>';
}

function clearFilter(kind) {
  closeSuggestions();
  $("recentWrap").hidden = true;
  if (kind === "q") {
    state.q = "";
    $("search").value = "";
    $("clear").hidden = true;
    closeSuggestions();
    $("recentWrap").hidden = true;
  } else if (kind === "store") {
    state.store = "all";
  } else if (kind === "category") {
    state.category = "all";
  } else if (kind === "inStock") {
    state.inStock = false;
  } else if (kind === "all") {
    state.q = "";
    state.store = "all";
    state.category = "all";
    state.inStock = false;
    state.sort = "relevance";
    $("search").value = "";
    $("clear").hidden = true;
    closeSuggestions();
    $("recentWrap").hidden = true;
  }
  state.listLimit = PAGE_SIZE;
  syncFilters();
  renderList();
}

function resetFilters(clearQuery) {
  state.store = "all";
  state.category = "all";
  state.sort = "relevance";
  state.inStock = false;
  state.listLimit = PAGE_SIZE;
  if (clearQuery) {
    state.q = "";
    $("search").value = "";
    $("clear").hidden = true;
    closeSuggestions();
    $("recentWrap").hidden = true;
  }
  syncFilters();
  renderList();
}

function openStore(storeId) {
  clearTimeout(searchTimer);
  state.q = "";
  state.store = storeId;
  state.category = "all";
  state.listLimit = PAGE_SIZE;
  $("search").value = "";
  $("clear").hidden = true;
  syncFilters();
  const store = (INDEX.stores || []).find((item) => item.id === storeId);
  toast("Showing " + (store ? store.name : "store") + " products");
  navigate("browse");
}

/* ============================================================
   Deals
   ============================================================ */

function dealRows() {
  const query = norm(state.q);
  const terms = query ? query.split(" ").filter(Boolean) : [];
  const rows = DEALS.filter((product) => {
    if (!terms.length) return true;
    const haystack = norm([
      product.name,
      product.brand,
      product.storeName,
      Array.isArray(product.category) ? product.category.join(" ") : ""
    ].join(" "));
    return terms.every((term) => haystack.includes(term));
  });

  const sorted = rows.slice();
  switch (state.dealSort) {
    case "saving":
      sorted.sort((a, b) => savingAmount(b) - savingAmount(a));
      break;
    case "price-asc":
      sorted.sort(byPriceAsc);
      break;
    case "price-desc":
      sorted.sort(byPriceDesc);
      break;
    default:
      sorted.sort((a, b) => discountPct(b) - discountPct(a));
      break;
  }
  return sorted;
}

function renderDeals() {
  if (!INDEX) return;
  const rows = dealRows();
  const shown = rows.slice(0, state.dealLimit);

  $("dealGrid").innerHTML = shown.map(productCard).join("");
  $("dealEmpty").hidden = rows.length !== 0;
  $("moreDeals").hidden = shown.length >= rows.length;
  $("dealCount").textContent = rows.length
    ? "Showing " + fmt(shown.length) + " of " + fmt(rows.length) + " price drops"
    : "0 price drops";
  $("dealSub").textContent = state.q.trim()
    ? "Discounts matching \u201c" + state.q.trim() + "\u201d, ranked by " + (state.dealSort === "saving" ? "saving" : state.dealSort === "price-asc" ? "price" : "discount") + "."
    : "The biggest current discounts across all tracked stores.";
  $("dealRefreshed").textContent = INDEX.sample
    ? "sample index"
    : "index updated " + formatTime(INDEX.generatedAt);
  document.title = "Current price drops \u2014 QuickCompare HK";
}

/* ============================================================
   Compare
   ============================================================ */

function buildGroups(rows) {
  const byKey = new Map();

  for (const product of rows) {
    const key = product.matchGroup
      ? "g:" + product.matchGroup
      : product.barcode
        ? "b:" + product.barcode
        : "n:" + norm(product.name);
    if (!byKey.has(key)) byKey.set(key, []);
    byKey.get(key).push(product);
  }

  const nameToKeys = new Map();
  for (const [key, items] of byKey) {
    for (const product of items) {
      const name = norm(product.name) + "|" + norm(product.size);
      if (!name || name === "|") continue;
      if (!nameToKeys.has(name)) nameToKeys.set(name, new Set());
      nameToKeys.get(name).add(key);
    }
  }

  const parent = new Map();
  for (const key of byKey.keys()) parent.set(key, key);

  const find = (x) => {
    while (parent.get(x) !== x) {
      parent.set(x, parent.get(parent.get(x)));
      x = parent.get(x);
    }
    return x;
  };

  const union = (a, b) => {
    const ra = find(a);
    const rb = find(b);
    if (ra !== rb) parent.set(ra, rb);
  };

  for (const keys of nameToKeys.values()) {
    const list = [...keys];
    for (let i = 1; i < list.length; i++) union(list[0], list[i]);
  }

  const merged = new Map();
  for (const [key, items] of byKey) {
    const root = find(key);
    if (!merged.has(root)) merged.set(root, []);
    merged.get(root).push(...items);
  }

  return [...merged.values()];
}

const COMPARE_STOP_WORDS = new Set([
  "the", "and", "with", "for", "of", "x", "pack", "pcs", "pc", "ml", "l",
  "g", "kg", "lt", "gm", "each", "unit", "set", "box", "pk", "bx", "st",
  "rl", "new", "old", "random", "packaging", "chilled", "hong", "kong",
  "consume", "within", "days", "best", "quality"
]);

function comparisonTokens(name) {
  return norm(name)
    .split(" ")
    .filter((token) => token && !COMPARE_STOP_WORDS.has(token) && !/^\d+(\.\d+)?$/.test(token));
}

function nameSimilarity(a, b) {
  const left = comparisonTokens(a);
  const right = comparisonTokens(b);
  if (!left.length || !right.length) return 0;
  const rightSet = new Set(right);
  let intersection = 0;
  for (const token of left) if (rightSet.has(token)) intersection++;
  return intersection / (left.length + right.length - intersection);
}

function barcodesOf(product) {
  return String(product.barcode || "")
    .split(/[,;|]+/)
    .map((value) => value.trim())
    .filter(Boolean);
}

function sharesBarcode(a, b) {
  const left = barcodesOf(a);
  if (!left.length) return false;
  const right = new Set(barcodesOf(b));
  return left.some((code) => right.has(code));
}

function renderCompare() {
  if (!INDEX) return;
  const rows = filteredProducts({ ignoreStore: true });
  const groups = buildGroups(rows);
  const comparable = [];
  let hidden = 0;

  for (const items of groups) {
    const stores = new Set(items.map((item) => item.store));
    if (stores.size < 2) continue;
    const priced = items.filter((item) => item.price != null);
    if (priced.length < 2) continue;

    const seenStores = new Set();
    const sorted = priced
      .slice()
      .sort(byPriceAsc)
      .filter((item) => {
        if (seenStores.has(item.store)) return false;
        seenStores.add(item.store);
        return true;
      });
    if (sorted.length < 2) continue;

    /*
     * matchGroup is generated by scripts/match.ps1 from brand + size + name +
     * image similarity. It is good, but a single item and a case of 12 can
     * still land in the same group. Drop rows with a very different name, and
     * hide groups whose cheapest and dearest prices are 2.5x apart.
     */
    const anchor = sorted[0];
    /*
     * matchGroup already proves equivalence: it was built from brand + size +
     * name tokens + image hash. Trust it. The text check below is only a
     * fallback for groups formed from a shared barcode or name, where PNS's
     * generic names ("Fresh Milk [ Hong Kong]") would otherwise fail it.
     */
    const sameMatchGroup = Boolean(anchor.matchGroup) &&
      sorted.every((item) => item.matchGroup === anchor.matchGroup);
    const verified = sameMatchGroup
      ? sorted
      : sorted.filter((item, index) =>
          index === 0 ||
          sharesBarcode(anchor, item) ||
          nameSimilarity(anchor.name, item.name) >= 0.4
        );
    if (verified.length < 2 || new Set(verified.map((item) => item.store)).size < 2) {
      hidden++;
      continue;
    }

    const cheapest = verified[0];
    const highest = verified[verified.length - 1];
    const ratio = Number(highest.price) / Number(cheapest.price);
    if (!Number.isFinite(ratio) || ratio >= 2.5) {
      hidden++;
      continue;
    }

    const imageProduct = verified.find((item) => item.image) || cheapest;

    comparable.push({
      name: cheapest.name,
      brand: cheapest.brand,
      size: cheapest.size,
      items: verified,
      cheapest,
      saving: Number(highest.price) - Number(cheapest.price),
      image: imageProduct.image,
      storeCount: new Set(verified.map((item) => item.store)).size
    });
  }

  comparable.sort((a, b) => b.saving - a.saving);
  const shown = comparable.slice(0, state.compareLimit);

  $("compare-count").textContent = comparable.length
    ? "Showing " + fmt(shown.length) + " of " + fmt(comparable.length) + " products listed by multiple stores"
    : "0 products listed by multiple stores";
  const hiddenNote = hidden
    ? " " + fmt(hidden) + " possible match" + (hidden === 1 ? "" : "es") + " hidden pending a pack-size check."
    : "";
  const storeNote = state.store !== "all"
    ? " Store filter is ignored here so every store can be compared."
    : "";
  $("compareSub").textContent = (comparable.length
    ? fmt(comparable.length) + " products are listed by more than one store. The cheapest option is shown first."
    : "No product is listed by more than one store with the current search.") + storeNote + hiddenNote;
  $("compare-empty").hidden = comparable.length !== 0;
  $("more-compare").hidden = shown.length >= comparable.length;
  $("compareRefreshed").textContent = INDEX.sample
    ? "sample index"
    : "index updated " + formatTime(INDEX.generatedAt);

  $("compare").innerHTML = shown.map((group) => {
    const rowsHtml = group.items.map((item, index) => {
      const itemMeta = storeMeta(item.store, item.storeName);
      const diff = group.cheapest.price != null && item.price != null
        ? Number(item.price) - Number(group.cheapest.price)
        : 0;
      const delta = index === 0
        ? `<em class="compare-delta is-best">best price</em>`
        : diff > 0
          ? `<em class="compare-delta">+${money(diff)}</em>`
          : `<em class="compare-delta">same</em>`;
      return `
        <div class="compare-row${index === 0 ? " cheapest" : ""}">
          <span class="compare-store">
            <i class="mini-dot" style="background:${itemMeta.color}"></i>
            ${esc(item.storeName || item.store)}
            ${index === 0 ? '<span class="best-badge">Best</span>' : ""}
          </span>
          <span class="compare-price${index === 0 ? " is-cheapest" : ""}">${money(item.price)}${delta}</span>
          <a class="compare-open" href="${esc(productUrl(item))}" target="_blank" rel="noopener noreferrer">
            Open <svg class="icon"><use href="#i-arrow"/></svg>
          </a>
        </div>
      `;
    }).join("");

    const saving = group.saving > 0
      ? `<p class="compare-saving"><svg class="icon"><use href="#i-check"/></svg> Save ${money(group.saving)} vs the highest price</p>`
      : `<p class="compare-saving"><svg class="icon"><use href="#i-check"/></svg> Same price at every store</p>`;

    return `
      <article class="compare-card">
        <div class="compare-head">
          <span class="compare-thumb${group.image ? "" : " img-fail"}">
            ${group.image ? `<img src="${esc(group.image)}" alt="" loading="lazy" decoding="async" onerror="this.style.display='none';this.parentElement.classList.add('img-fail')">` : ""}
            <span class="thumb-fallback">${esc(initialOf(group.brand || group.name))}</span>
          </span>
          <div class="compare-title">
            <h3>${esc(group.name)}</h3>
            <p>${esc([group.brand, group.size].filter(Boolean).join(" \u00b7 ") || group.storeCount + " stores")}</p>
          </div>
        </div>
        <div class="compare-rows">${rowsHtml}</div>
        ${saving}
      </article>
    `;
  }).join("");

  document.title = "Compare stores \u2014 QuickCompare HK";
}

/* ============================================================
   Alerts
   ============================================================ */

function readAlerts() {
  const raw = readLS("qc_alerts", []);
  if (!Array.isArray(raw)) return [];
  return raw.filter((alert) => alert && alert.product && Number(alert.target) > 0).slice(0, 20);
}

function bestMatchFor(query) {
  const terms = norm(query).split(" ").filter(Boolean);
  if (!terms.length) return null;
  let best = null;

  for (const product of INDEX.products) {
    if (product.price == null) continue;
    const haystack = norm([
      product.name,
      product.brand,
      product.barcode,
      Array.isArray(product.category) ? product.category.join(" ") : ""
    ].join(" "));
    if (!terms.every((term) => haystack.includes(term))) continue;
    if (!best || Number(product.price) < Number(best.price)) best = product;
  }

  return best;
}

function renderAlerts() {
  if (!INDEX) return;
  const list = $("alertList");
  const empty = $("alertEmpty");
  const clear = $("clearAlerts");

  clear.hidden = ALERTS.length === 0;
  empty.hidden = ALERTS.length !== 0;

  const matches = new Map();
  let met = 0;
  for (const alert of ALERTS) {
    const match = bestMatchFor(alert.product);
    matches.set(alert.id, match);
    if (match && Number(match.price) <= Number(alert.target)) met++;
  }

  $("alertSummary").textContent = ALERTS.length
    ? fmt(ALERTS.length) + " saved alert" + (ALERTS.length === 1 ? "" : "s") + " \u00b7 " + met + " target" + (met === 1 ? "" : "s") + " met"
    : "No alerts saved yet.";

  list.innerHTML = ALERTS.map((alert) => {
    const match = matches.get(alert.id) || null;
    const price = match ? Number(match.price) : null;
    const isMet = price != null && price <= Number(alert.target);
    const matchLine = match
      ? `Cheapest now: <a href="${esc(productUrl(match))}" target="_blank" rel="noopener noreferrer">${esc(match.name)}</a> \u00b7 ${esc(match.storeName || match.store)} \u00b7 ${money(match.price)}`
      : "No current product in the index matches this search.";
    const status = match
      ? (isMet ? "Target met" : "Above target")
      : "No match";

    return `
      <article class="alert-item">
        <div class="alert-item-top">
          <div>
            <h3>${esc(alert.product)}</h3>
            <p>Target ${money(alert.target)} \u00b7 saved ${esc(timeAgo(alert.createdAt))}</p>
          </div>
          <button class="alert-remove" type="button" data-alert-remove="${esc(alert.id)}" aria-label="Remove alert for ${esc(alert.product)}">
            <svg class="icon"><use href="#i-trash"/></svg>
          </button>
        </div>
        <p class="alert-match">${matchLine}</p>
        <div class="alert-status${isMet ? " met" : ""}">
          <span>${status}</span>
          <b>${match ? money(match.price) : "\u2014"}</b>
        </div>
      </article>
    `;
  }).join("");

  document.title = "Price alerts \u2014 QuickCompare HK";
}

function saveAlert(product, target) {
  ALERTS = ALERTS.filter((alert) => String(alert.product).toLowerCase() !== product.toLowerCase());
  ALERTS.unshift({
    id: "a" + Date.now().toString(36) + Math.random().toString(36).slice(2, 6),
    product,
    target,
    createdAt: new Date().toISOString()
  });
  ALERTS = ALERTS.slice(0, 20);
  writeLS("qc_alerts", ALERTS);
}

function removeAlert(id) {
  ALERTS = ALERTS.filter((alert) => alert.id !== id);
  writeLS("qc_alerts", ALERTS);
  renderAlerts();
  toast("Alert removed");
}

/* ============================================================
   Profile
   ============================================================ */

function renderProfile() {
  if (!INDEX || !STATS) return;

  $("profileDistrict").textContent = state.district;

  const districtSelect = $("districtSelect");
  if (districtSelect) {
    districtSelect.innerHTML = DISTRICTS.map((district) =>
      `<option value="${esc(district)}">${esc(district)}</option>`
    ).join("");
    districtSelect.value = state.district;
  }

  $("profileStats").innerHTML = `
    <div><strong>${fmt(STATS.totals.products)}</strong><span>Products</span></div>
    <div><strong>${fmt(STATS.totals.stores)}</strong><span>Stores</span></div>
    <div><strong>${fmt(ALERTS.length)}</strong><span>Alerts</span></div>
  `;

  $("profileStores").innerHTML = (INDEX.stores || []).map((store) => `
    <a href="${esc(store.url)}" target="_blank" rel="noopener noreferrer">
      ${esc(store.name)}
      <svg class="icon"><use href="#i-arrow"/></svg>
    </a>
  `).join("");

  $("aboutProducts").textContent = fmt(STATS.totals.products);
  $("aboutCategories").textContent = fmt(STATS.totals.categories);
  $("aboutRefresh").textContent = INDEX.sample ? "sample index" : formatTime(INDEX.generatedAt);

  $$("#themeSegment button").forEach((button) => {
    button.classList.toggle("active", button.dataset.theme === state.theme);
  });

  document.title = "Profile & data \u2014 QuickCompare HK";
}

/* ============================================================
   Search + suggestions
   ============================================================ */

function saveRecent(query) {
  const clean = String(query || "").trim();
  if (!clean) return;
  RECENT = [clean, ...RECENT.filter((item) => item.toLowerCase() !== clean.toLowerCase())].slice(0, 6);
  writeLS("qc_recent_searches", RECENT);
  renderRecent();
}

function renderRecent() {
  const wrap = $("recentWrap");
  const list = $("recentList");
  if (!RECENT.length) {
    wrap.hidden = true;
    list.innerHTML = "";
    return;
  }
  list.innerHTML = RECENT.map((query) => `
    <button class="recent-chip" type="button" data-query="${esc(query)}">${esc(query)}</button>
  `).join("");
}

function showRecent() {
  if (!RECENT.length) {
    $("recentWrap").hidden = true;
    return;
  }
  renderRecent();
  $("recentWrap").hidden = false;
}

function suggestionCandidates(query) {
  const normalized = norm(query);
  const terms = normalized.split(" ").filter(Boolean);
  const candidates = [];

  for (const product of INDEX.products) {
    const name = norm(product.name);
    const brand = norm(product.brand);
    const haystack = name + " " + brand + " " + (product.barcode || "");
    if (!terms.every((term) => haystack.includes(term))) continue;

    let score = 0;
    if (name === normalized) score += 130;
    else if (name.startsWith(normalized)) score += 85;
    else if (name.includes(normalized)) score += 45;
    if (brand === normalized) score += 100;
    else if (brand.startsWith(normalized)) score += 55;
    else if (brand.includes(normalized)) score += 30;
    if ((product.barcode || "").toLowerCase().includes(normalized)) score += 150;
    if (product.inStock !== false) score += 4;

    candidates.push({ product, score });
    if (candidates.length >= 320) break;
  }

  candidates.sort((a, b) => b.score - a.score);
  return candidates.slice(0, 6).map((item) => item.product);
}

function showSuggestions(query) {
  const value = String(query || "").trim();
  const box = $("suggestions");

  if (!INDEX || !value) {
    closeSuggestions();
    if ($("search") === document.activeElement) showRecent();
    return;
  }

  $("recentWrap").hidden = true;
  const matches = suggestionCandidates(value);

  box.innerHTML = matches.map((product) => {
    const meta = storeMeta(product.store, product.storeName);
    const thumb = product.image
      ? `<img src="${esc(product.image)}" alt="" loading="lazy" decoding="async" onerror="this.style.display='none'">`
      : initialOf(product.brand || product.name);
    return `
      <button class="suggestion" type="button" data-query="${esc(product.name)}">
        <span class="suggestion-thumb">${thumb}</span>
        <span class="suggestion-text">
          <span class="suggestion-name">${esc(product.name)}</span>
          <span class="suggestion-meta">
            <i class="mini-dot" style="background:${meta.color};display:inline-block;margin-right:4px"></i>
            ${esc(product.storeName || product.store)}${product.size ? " \u00b7 " + esc(product.size) : ""}
          </span>
        </span>
        <span class="suggestion-price">${money(product.price)}</span>
      </button>
    `;
  }).join("") + `
    <button class="suggestion-all" type="button" data-query="${esc(value)}">
      <svg class="icon icon-sm"><use href="#i-search"/></svg>
      Search all results for \u201c${esc(value)}\u201d
    </button>
  `;

  box.hidden = false;
  suggestItems = $$(".suggestion, .suggestion-all", box);
  suggestIndex = -1;
}

function closeSuggestions() {
  const box = $("suggestions");
  if (box) box.hidden = true;
  suggestItems = [];
  suggestIndex = -1;
}

function setActiveSuggestion(index) {
  if (!suggestItems.length) return;
  suggestIndex = (index + suggestItems.length) % suggestItems.length;
  suggestItems.forEach((item, i) => item.classList.toggle("is-active", i === suggestIndex));
  suggestItems[suggestIndex].scrollIntoView({ block: "nearest" });
}

function applyQuery(query, options = {}) {
  clearTimeout(searchTimer);
  const clean = String(query || "").trim();
  state.q = clean;
  $("search").value = clean;
  $("clear").hidden = !clean;
  if (options.store) state.store = options.store;
  if (options.category) state.category = options.category;
  state.listLimit = PAGE_SIZE;
  if (clean) saveRecent(clean);
  closeSuggestions();
  $("recentWrap").hidden = true;
  if (document.activeElement === $("search")) $("search").blur();
  syncFilters();
  navigate("browse");
}

/* ============================================================
   Theme + district
   ============================================================ */

function applyTheme(preference, persist = true) {
  const pref = ["system", "light", "dark"].includes(preference) ? preference : "system";
  state.theme = pref;
  const dark = pref === "dark" || (pref === "system" &&
    window.matchMedia("(prefers-color-scheme: dark)").matches);

  document.documentElement.classList.toggle("dark", dark);
  const meta = document.querySelector('meta[name="theme-color"]');
  if (meta) meta.setAttribute("content", dark ? "#000000" : "#ffffff");

  if (persist) writeLS("qc_theme", pref);

  $$("#themeSegment button").forEach((button) => {
    button.classList.toggle("active", button.dataset.theme === pref);
  });

  const themeButton = $("themeBtn");
  if (themeButton) {
    themeButton.setAttribute("aria-label", dark ? "Switch to light mode" : "Switch to dark mode");
  }
}

function toggleTheme() {
  const dark = document.documentElement.classList.contains("dark");
  applyTheme(dark ? "light" : "dark");
  toast(dark ? "Light mode on" : "Dark mode on");
}

function renderDistrictOptions() {
  const element = $("locOptions");
  if (!element) return;
  element.innerHTML = DISTRICTS.map((district) => `
    <button class="loc-option" type="button" role="menuitemradio" aria-checked="${district === state.district}" data-district="${esc(district)}">
      <span>${esc(district)}</span>
      ${district === state.district ? '<svg class="icon"><use href="#i-check"/></svg>' : ""}
    </button>
  `).join("");
}

function setDistrict(district, options = {}) {
  const next = DISTRICTS.includes(district) ? district : "Hong Kong";
  state.district = next;
  if (options.persist !== false) writeLS("qc_district", next);
  const label = $("locLabel");
  if (label) label.textContent = next;
  const profile = $("profileDistrict");
  if (profile) profile.textContent = next;
  const select = $("districtSelect");
  if (select) select.value = next;
  renderDistrictOptions();
  if (!options.silent) toast("Shopping in " + next);
}

function toggleLocMenu() {
  const menu = $("locMenu");
  const button = $("locBtn");
  const open = menu.hidden;
  menu.hidden = !open;
  button.setAttribute("aria-expanded", String(open));
  if (open) renderDistrictOptions();
}

function closeLocMenu() {
  const menu = $("locMenu");
  const button = $("locBtn");
  if (!menu) return;
  menu.hidden = true;
  if (button) button.setAttribute("aria-expanded", "false");
}

/* ============================================================
   Navigation
   ============================================================ */

function updateTitle(view) {
  const titles = {
    home: "QuickCompare HK \u2014 Compare supermarket prices across Hong Kong",
    browse: "All products \u2014 QuickCompare HK",
    deals: "Current price drops \u2014 QuickCompare HK",
    compare: "Compare stores \u2014 QuickCompare HK",
    alerts: "Price alerts \u2014 QuickCompare HK",
    profile: "Profile & data \u2014 QuickCompare HK"
  };
  document.title = titles[view] || titles.home;
}

function navigate(view, options = {}) {
  const target = VIEWS.includes(view) ? view : "home";
  const push = options.push !== false;
  const scroll = options.scroll !== false;
  const keepSuggestions = options.keepSuggestions === true;
  const changed = state.view !== target;
  state.view = target;

  for (const name of VIEWS) {
    const element = $("view-" + name);
    if (element) element.hidden = name !== target;
  }

  $$(".top-link, .bottom-link").forEach((button) => {
    const active = button.dataset.nav === target;
    button.classList.toggle("active", active);
    if (active) button.setAttribute("aria-current", "page");
    else button.removeAttribute("aria-current");
  });

  if (!keepSuggestions) closeSuggestions();
  closeLocMenu();

  if (target === "home") renderHome();
  else if (target === "browse") renderList();
  else if (target === "deals") renderDeals();
  else if (target === "compare") renderCompare();
  else if (target === "alerts") renderAlerts();
  else if (target === "profile") renderProfile();

  updateTitle(target);
  if (target === "browse") {
    const title = $("browseTitle").textContent;
    document.title = title + " \u2014 QuickCompare HK";
  }

  if (push && location.hash !== "#" + target) {
    history.pushState(null, "", "#" + target);
  }

  if (scroll && changed) {
    window.scrollTo({ top: 0, behavior: "smooth" });
  }
}

/* ============================================================
   Events
   ============================================================ */

function bindEvents() {
  const search = $("search");
  const clear = $("clear");
  const form = $("searchForm");

  search.addEventListener("input", () => {
    state.q = search.value;
    clear.hidden = !search.value;
    if (search.value.trim()) {
      showSuggestions(search.value);
    } else {
      closeSuggestions();
      showRecent();
    }

    clearTimeout(searchTimer);
    searchTimer = setTimeout(() => {
      if (state.q.trim()) {
        state.listLimit = PAGE_SIZE;
        if (state.view !== "browse") navigate("browse", { scroll: false, keepSuggestions: true });
        else renderList();
      } else if (state.view === "browse") {
        state.listLimit = PAGE_SIZE;
        renderList();
      }
    }, 230);
  });

  search.addEventListener("focus", () => {
    if (search.value.trim()) showSuggestions(search.value);
    else showRecent();
  });

  search.addEventListener("keydown", (event) => {
    if (event.key === "ArrowDown") {
      event.preventDefault();
      if ($("suggestions").hidden) showSuggestions(search.value);
      if (suggestItems.length) setActiveSuggestion(suggestIndex + 1);
    } else if (event.key === "ArrowUp") {
      event.preventDefault();
      if (suggestItems.length) setActiveSuggestion(suggestIndex - 1);
    } else if (event.key === "Enter") {
      if (suggestIndex >= 0 && suggestItems[suggestIndex]) {
        event.preventDefault();
        suggestItems[suggestIndex].click();
      }
    } else if (event.key === "Escape") {
      closeSuggestions();
      search.blur();
    }
  });

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    const value = search.value.trim();
    if (!value) {
      search.focus();
      return;
    }
    if (suggestIndex >= 0 && suggestItems[suggestIndex]) {
      suggestItems[suggestIndex].click();
      return;
    }
    applyQuery(value);
  });

  clear.addEventListener("click", () => {
    clearTimeout(searchTimer);
    state.q = "";
    search.value = "";
    clear.hidden = true;
    closeSuggestions();
    showRecent();
    state.listLimit = PAGE_SIZE;
    if (state.view === "browse") renderList();
    search.focus();
  });

  $("store").addEventListener("change", (event) => {
    state.store = event.target.value;
    state.listLimit = PAGE_SIZE;
    renderList();
  });

  $("category").addEventListener("change", (event) => {
    state.category = event.target.value;
    state.listLimit = PAGE_SIZE;
    renderList();
  });

  $("sort").addEventListener("change", (event) => {
    state.sort = event.target.value;
    state.listLimit = PAGE_SIZE;
    renderList();
  });

  $("inStock").addEventListener("change", (event) => {
    state.inStock = event.target.checked;
    state.listLimit = PAGE_SIZE;
    renderList();
  });

  $("dealSort").addEventListener("change", (event) => {
    state.dealSort = event.target.value;
    state.dealLimit = DEAL_PAGE_SIZE;
    renderDeals();
  });

  $("more").addEventListener("click", () => {
    state.listLimit += PAGE_SIZE;
    renderList();
  });

  $("moreDeals").addEventListener("click", () => {
    state.dealLimit += DEAL_PAGE_SIZE;
    renderDeals();
  });

  $("more-compare").addEventListener("click", () => {
    state.compareLimit += COMPARE_PAGE_SIZE;
    renderCompare();
  });

  $("clearFilters").addEventListener("click", () => resetFilters(false));
  $("emptyReset").addEventListener("click", () => resetFilters(true));

  $("alertForm").addEventListener("submit", (event) => {
    event.preventDefault();
    const product = $("alertProduct").value.trim();
    const target = Number($("alertPrice").value);
    const note = $("alertNote");

    if (!product || product.length < 2) {
      note.hidden = false;
      note.textContent = "Enter a product name or brand.";
      return;
    }
    if (!Number.isFinite(target) || target <= 0) {
      note.hidden = false;
      note.textContent = "Enter a target price above HK$0.";
      return;
    }

    saveAlert(product, target);
    renderAlerts();
    $("alertProduct").value = "";
    $("alertPrice").value = "";
    const match = bestMatchFor(product);
    note.hidden = false;
    note.textContent = match
      ? "Alert saved. The cheapest current match is " + money(match.price) + " at " + (match.storeName || match.store) + "."
      : "Alert saved. There is no current match in the index yet.";
    toast("Price alert saved");
  });

  $("clearAlerts").addEventListener("click", () => {
    if (!ALERTS.length) return;
    if (!window.confirm("Clear all saved price alerts?")) return;
    ALERTS = [];
    writeLS("qc_alerts", ALERTS);
    renderAlerts();
    toast("All alerts cleared");
  });

  $("clearLocal").addEventListener("click", () => {
    ["qc_alerts", "qc_recent_searches", "qc_theme", "qc_district"].forEach(removeLS);
    ALERTS = [];
    RECENT = [];
    state.theme = "system";
    applyTheme("system", false);
    setDistrict("Hong Kong", { persist: false, silent: true });
    renderAlerts();
    renderProfile();
    renderRecent();
    $("clear").hidden = true;
    const note = $("localNote");
    if (note) {
      note.hidden = false;
      note.textContent = "Saved data cleared.";
    }
    toast("Saved data cleared");
  });

  $("themeBtn").addEventListener("click", toggleTheme);
  $("footerTheme").addEventListener("click", toggleTheme);

  $$("#themeSegment button").forEach((button) => {
    button.addEventListener("click", () => {
      applyTheme(button.dataset.theme);
      toast(button.dataset.theme === "system" ? "Following system theme" : button.dataset.theme + " mode on");
    });
  });

  $("locBtn").addEventListener("click", toggleLocMenu);

  $("districtSelect").addEventListener("change", (event) => {
    setDistrict(event.target.value);
  });

  document.addEventListener("click", (event) => {
    const target = event.target;

    if (target.closest("[data-nav], [data-store], [data-query], [data-clear]")) {
      clearTimeout(searchTimer);
    }

    const nav = target.closest("[data-nav]");
    if (nav) {
      event.preventDefault();
      navigate(nav.dataset.nav);
      return;
    }

    const storeButton = target.closest("[data-store]");
    if (storeButton) {
      event.preventDefault();
      openStore(storeButton.dataset.store);
      return;
    }

    const queryButton = target.closest("[data-query]");
    if (queryButton) {
      event.preventDefault();
      applyQuery(queryButton.dataset.query);
      return;
    }

    const clearButton = target.closest("[data-clear]");
    if (clearButton) {
      event.preventDefault();
      clearFilter(clearButton.dataset.clear);
      return;
    }

    const alertRemove = target.closest("[data-alert-remove]");
    if (alertRemove) {
      event.preventDefault();
      removeAlert(alertRemove.dataset.alertRemove);
      return;
    }

    const districtButton = target.closest("[data-district]");
    if (districtButton) {
      event.preventDefault();
      setDistrict(districtButton.dataset.district);
      closeLocMenu();
      return;
    }

    if (!target.closest("#locWrap")) closeLocMenu();
    if (!target.closest(".search-shell")) closeSuggestions();
  });

  document.addEventListener("keydown", (event) => {
    const isTyping = event.target && (
      event.target.tagName === "INPUT" ||
      event.target.tagName === "TEXTAREA" ||
      event.target.tagName === "SELECT"
    );

    if ((event.ctrlKey || event.metaKey) && String(event.key).toLowerCase() === "k") {
      event.preventDefault();
      search.focus();
      search.select();
      if (search.value.trim()) showSuggestions(search.value);
      else showRecent();
      return;
    }

    if (event.key === "Escape") {
      closeSuggestions();
      closeLocMenu();
    }

    if (event.key === "/" && !isTyping) {
      event.preventDefault();
      search.focus();
    }
  });

  window.addEventListener("popstate", () => {
    const view = location.hash.replace("#", "");
    navigate(VIEWS.includes(view) ? view : "home", { push: false });
  });

  window.addEventListener("hashchange", () => {
    const view = location.hash.replace("#", "");
    if (VIEWS.includes(view) && view !== state.view) navigate(view, { push: false });
  });

  const media = window.matchMedia("(prefers-color-scheme: dark)");
  const onSchemeChange = () => {
    if (state.theme === "system") applyTheme("system", false);
  };
  if (media.addEventListener) media.addEventListener("change", onSchemeChange);
  else if (media.addListener) media.addListener(onSchemeChange);
}

/* ============================================================
   Boot
   ============================================================ */

function showLoading() {
  const cards = (count, height, width) => Array.from({ length: count }, () =>
    `<div class="skeleton" style="height:${height}px;${width ? "width:" + width + "px;flex:none" : ""}"></div>`
  ).join("");

  $("storeStrip").innerHTML = cards(3, 74);
  $("trendingStrip").innerHTML = cards(6, 158, 142);
  $("dropStrip").innerHTML = cards(4, 250, 196);
  $("brandCloud").innerHTML = cards(8, 34, 92);
}

async function init() {
  bindEvents();
  showLoading();

  const savedTheme = readLS("qc_theme", "system");
  applyTheme(["system", "light", "dark"].includes(savedTheme) ? savedTheme : "system", false);
  RECENT = readLS("qc_recent_searches", []);
  if (!Array.isArray(RECENT)) RECENT = [];
  RECENT = RECENT.filter((item) => typeof item === "string").slice(0, 6);
  ALERTS = readAlerts();
  const savedDistrict = readLS("qc_district", "Hong Kong");
  setDistrict(DISTRICTS.includes(savedDistrict) ? savedDistrict : "Hong Kong", {
    persist: false,
    silent: true
  });

  try {
    INDEX = await loadIndex();
    buildDerived();
    buildFilters();
    syncFilters();
    renderGlobalMeta();
    renderRecent();

    const initial = location.hash.replace("#", "");
    navigate(VIEWS.includes(initial) ? initial : "home", { push: false, scroll: false });
  } catch (error) {
    console.error("init failed", error);
    $("topMeta").textContent = "Failed to load index";
    $("heroName").textContent = "Could not load the price index.";
    $("heroStore").textContent = error.message;
    toast("Failed to load the price index");
  }
}

init();

