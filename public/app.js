const money = new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'EUR', maximumFractionDigits: 0 });
const appContent = document.querySelector('#app-content');
const dialog = document.querySelector('#action-dialog');
const dialogContent = document.querySelector('#dialog-content');
const searchInput = document.querySelector('#global-search');
const sectionName = document.querySelector('#current-section');
const toast = document.querySelector('#toast');

const labels = {
  dashboard: "Vue d'ensemble",
  quotes: 'Devis',
  orders: 'Commandes',
  customers: 'Clients',
  products: 'Catalogue',
  stock: 'Stocks',
  invoices: 'Facturation',
  purchasing: 'Achats',
};

const state = {
  view: 'dashboard',
  filter: 'Tous',
  search: '',
  orders: [
    { ref: 'CMD-2026-0418', customer: 'Atelier Suzon', initials: 'AS', date: '13 oct. 2026', amount: 4280, status: 'À préparer', tone: 'orange', owner: 'Nora Petit', avatar: '' },
    { ref: 'CMD-2026-0417', customer: 'Hôtel Valmy', initials: 'HV', date: '13 oct. 2026', amount: 3640, status: 'Confirmée', tone: 'green', owner: 'Claire Martin', avatar: 'warm' },
    { ref: 'CMD-2026-0416', customer: 'Comptoir Luciole', initials: 'CL', date: '12 oct. 2026', amount: 1280, status: 'En attente', tone: 'blue', owner: 'Nora Petit', avatar: 'blue' },
    { ref: 'CMD-2026-0415', customer: 'Maison Ravel', initials: 'MR', date: '12 oct. 2026', amount: 5890, status: 'Confirmée', tone: 'green', owner: 'Claire Martin', avatar: 'yellow' },
    { ref: 'CMD-2026-0414', customer: 'Les Belles Heures', initials: 'BH', date: '10 oct. 2026', amount: 2175, status: 'Expédiée', tone: 'blue', owner: 'Nora Petit', avatar: 'warm' },
    { ref: 'CMD-2026-0413', customer: 'Studio Orme', initials: 'SO', date: '9 oct. 2026', amount: 960, status: 'À préparer', tone: 'orange', owner: 'Claire Martin', avatar: 'blue' },
  ],
  quotes: [
    { ref: 'DEV-2026-0208', customer: 'Maison Ravel', initials: 'MR', date: '13 oct. 2026', amount: 6240, status: 'À relancer', tone: 'orange', owner: 'Claire Martin', avatar: 'yellow' },
    { ref: 'DEV-2026-0207', customer: 'L’Étage Paris', initials: 'LP', date: '12 oct. 2026', amount: 3180, status: 'Envoyé', tone: 'blue', owner: 'Nora Petit', avatar: 'warm' },
    { ref: 'DEV-2026-0206', customer: 'Atelier Suzon', initials: 'AS', date: '11 oct. 2026', amount: 8750, status: 'Accepté', tone: 'green', owner: 'Claire Martin', avatar: '' },
    { ref: 'DEV-2026-0205', customer: 'Café Junot', initials: 'CJ', date: '10 oct. 2026', amount: 1490, status: 'Brouillon', tone: 'gray', owner: 'Nora Petit', avatar: 'blue' },
    { ref: 'DEV-2026-0204', customer: 'Hôtel Valmy', initials: 'HV', date: '8 oct. 2026', amount: 4920, status: 'Envoyé', tone: 'blue', owner: 'Claire Martin', avatar: 'warm' },
  ],
  customers: [
    { ref: 'CLI-0048', customer: 'Atelier Suzon', initials: 'AS', subtitle: 'contact@ateliersuzon.fr', date: 'Paris, 11e', amount: 18450, status: 'Actif', tone: 'green', owner: 'Net 30 jours', avatar: '' },
    { ref: 'CLI-0047', customer: 'Hôtel Valmy', initials: 'HV', subtitle: 'achats@hotelvalmy.fr', date: 'Lyon, 2e', amount: 32180, status: 'Actif', tone: 'green', owner: 'Net 45 jours', avatar: 'warm' },
    { ref: 'CLI-0046', customer: 'Comptoir Luciole', initials: 'CL', subtitle: 'bonjour@luciole.fr', date: 'Bordeaux, 1er', amount: 9840, status: 'Actif', tone: 'green', owner: 'Net 30 jours', avatar: 'blue' },
    { ref: 'CLI-0045', customer: 'Maison Ravel', initials: 'MR', subtitle: 'gestion@maisonravel.fr', date: 'Nantes, centre', amount: 27890, status: 'À surveiller', tone: 'orange', owner: 'Net 30 jours', avatar: 'yellow' },
    { ref: 'CLI-0044', customer: 'Les Belles Heures', initials: 'BH', subtitle: 'contact@bellesheures.fr', date: 'Lille, Vieux-Lille', amount: 12760, status: 'Actif', tone: 'green', owner: 'Net 30 jours', avatar: 'warm' },
    { ref: 'CLI-0043', customer: 'Studio Orme', initials: 'SO', subtitle: 'hello@studioorme.fr', date: 'Biarritz, centre', amount: 7650, status: 'Actif', tone: 'green', owner: 'Comptant', avatar: 'blue' },
  ],
  products: [
    { ref: 'CH-0142', customer: 'Chaise Alba', initials: 'CH', subtitle: 'Mobilier · Chêne huilé', date: 'À l’unité', amount: 385, status: 'En stock', tone: 'green', owner: '24 unités', avatar: '' },
    { ref: 'LU-0088', customer: 'Lampe Noro', initials: 'LU', subtitle: 'Éclairage · Laiton brossé', date: 'À l’unité', amount: 240, status: 'Stock bas', tone: 'orange', owner: '3 unités', avatar: 'yellow' },
    { ref: 'TA-0230', customer: 'Table basse Sève', initials: 'TA', subtitle: 'Mobilier · Frêne naturel', date: 'À l’unité', amount: 620, status: 'En stock', tone: 'green', owner: '11 unités', avatar: 'warm' },
    { ref: 'AS-0014', customer: 'Assise Mistral', initials: 'AS', subtitle: 'Assise · Lin sauge', date: 'À l’unité', amount: 495, status: 'En stock', tone: 'green', owner: '18 unités', avatar: 'blue' },
    { ref: 'VA-0102', customer: 'Vase Dune', initials: 'VA', subtitle: 'Décoration · Céramique', date: 'À l’unité', amount: 78, status: 'Rupture', tone: 'red', owner: '0 unité', avatar: 'yellow' },
  ],
  invoices: [
    { ref: 'FAC-2026-0891', customer: 'Atelier Suzon', initials: 'AS', date: 'Échéance 28 oct.', amount: 2860, status: 'À régler', tone: 'orange', owner: 'Facture client', avatar: '' },
    { ref: 'FAC-2026-0890', customer: 'Hôtel Valmy', initials: 'HV', date: 'Échéance 24 oct.', amount: 3640, status: 'Payée', tone: 'green', owner: 'Facture client', avatar: 'warm' },
    { ref: 'FAC-2026-0889', customer: 'Maison Ravel', initials: 'MR', date: 'Échéance 19 oct.', amount: 1750, status: 'En retard', tone: 'red', owner: 'Facture client', avatar: 'yellow' },
    { ref: 'FAC-2026-0888', customer: 'Comptoir Luciole', initials: 'CL', date: 'Échéance 17 oct.', amount: 1280, status: 'Partielle', tone: 'blue', owner: 'Facture client', avatar: 'blue' },
    { ref: 'FAC-2026-0887', customer: 'Studio Orme', initials: 'SO', date: 'Échéance 15 oct.', amount: 960, status: 'À régler', tone: 'orange', owner: 'Facture client', avatar: 'blue' },
  ],
  purchasing: [
    { ref: 'ACH-2026-0126', customer: 'Bois & Matières', initials: 'BM', date: 'Livraison 16 oct.', amount: 4820, status: 'Confirmée', tone: 'green', owner: 'Nora Petit', avatar: 'yellow' },
    { ref: 'ACH-2026-0125', customer: 'Lumière Atelier', initials: 'LA', date: 'Livraison 17 oct.', amount: 2160, status: 'À approuver', tone: 'orange', owner: 'Claire Martin', avatar: 'warm' },
    { ref: 'ACH-2026-0124', customer: 'Textile du Nord', initials: 'TN', date: 'Livraison 20 oct.', amount: 1780, status: 'Partiellement reçue', tone: 'blue', owner: 'Nora Petit', avatar: 'blue' },
    { ref: 'ACH-2026-0123', customer: 'Céramique Fabre', initials: 'CF', date: 'Livrée 12 oct.', amount: 940, status: 'Réceptionnée', tone: 'green', owner: 'Claire Martin', avatar: '' },
  ],
  stock: [
    { ref: 'CH-0142', customer: 'Chaise Alba', initials: 'CH', subtitle: 'Mobilier · Chêne huilé', date: 'Dépôt principal', amount: 24, status: 'Disponible', tone: 'green', owner: 'Seuil : 8', avatar: '' },
    { ref: 'LU-0088', customer: 'Lampe Noro', initials: 'LU', subtitle: 'Éclairage · Laiton brossé', date: 'Dépôt principal', amount: 3, status: 'Stock bas', tone: 'orange', owner: 'Seuil : 6', avatar: 'yellow' },
    { ref: 'TA-0230', customer: 'Table basse Sève', initials: 'TA', subtitle: 'Mobilier · Frêne naturel', date: 'Dépôt principal', amount: 11, status: 'Disponible', tone: 'green', owner: 'Seuil : 4', avatar: 'warm' },
    { ref: 'AS-0014', customer: 'Assise Mistral', initials: 'AS', subtitle: 'Assise · Lin sauge', date: 'Dépôt secondaire', amount: 18, status: 'Disponible', tone: 'green', owner: 'Seuil : 6', avatar: 'blue' },
    { ref: 'VA-0102', customer: 'Vase Dune', initials: 'VA', subtitle: 'Décoration · Céramique', date: 'Dépôt principal', amount: 0, status: 'Rupture', tone: 'red', owner: 'Seuil : 4', avatar: 'yellow' },
  ],
};

const viewConfig = {
  quotes: { title: 'Devis', subtitle: 'Préparez vos offres, suivez leur envoi et repérez les relances à faire.', eyebrow: 'VENTES · OFFRES', button: 'Nouveau devis', ref: 'Référence', amount: 'Montant HT', owner: 'Responsable', filters: ['Tous', 'À relancer', 'Envoyé', 'Accepté', 'Brouillon'], summary: ['8 devis ouverts', '3 à relancer', '12 480 € en attente'] },
  orders: { title: 'Commandes clients', subtitle: 'Suivez les commandes confirmées, les préparations et les livraisons.', eyebrow: 'VENTES · COMMANDES', button: 'Nouvelle commande', ref: 'Commande', amount: 'Montant HT', owner: 'Commercial', filters: ['Tous', 'À préparer', 'Confirmée', 'En attente', 'Expédiée'], summary: ['24 commandes actives', '6 à préparer', '18 240 € à livrer'] },
  customers: { title: 'Clients', subtitle: 'Retrouvez vos comptes, contacts et conditions commerciales.', eyebrow: 'RÉFÉRENTIEL · TIERS', button: 'Ajouter un client', ref: 'Code client', amount: 'CA · 12 mois', owner: 'Conditions', filters: ['Tous', 'Actif', 'À surveiller'], summary: ['48 clients', '42 actifs', '3 comptes à surveiller'] },
  products: { title: 'Catalogue produits', subtitle: 'Articles, services et disponibilité des références.', eyebrow: 'RÉFÉRENTIEL · PRODUITS', button: 'Nouveau produit', ref: 'Référence', amount: 'Prix unitaire', owner: 'Disponibilité', filters: ['Tous', 'En stock', 'Stock bas', 'Rupture'], summary: ['126 références', '8 stocks bas', '4 ruptures'] },
  invoices: { title: 'Factures clients', subtitle: 'Suivez les échéances, les paiements reçus et les montants à recouvrer.', eyebrow: 'FINANCE · FACTURATION', button: 'Préparer une facture', ref: 'Document', amount: 'Montant TTC', owner: 'Type', filters: ['Tous', 'À régler', 'En retard', 'Partielle', 'Payée'], summary: ['36 factures ouvertes', '4 en retard', '21 480 € à encaisser'] },
  purchasing: { title: 'Achats fournisseurs', subtitle: 'Commandes d’achat, approbations et réceptions attendues.', eyebrow: 'ACHATS · APPROVISIONNEMENT', button: 'Nouvel achat', ref: 'Commande', amount: 'Montant HT', owner: 'Acheteur', filters: ['Tous', 'À approuver', 'Confirmée', 'Partiellement reçue', 'Réceptionnée'], summary: ['12 achats ouverts', '2 à approuver', '8 760 € engagés'] },
};

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (character) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[character]);
}

function personCell(record) {
  return `<div class="person-cell"><span class="person-avatar ${record.avatar ?? ''}">${escapeHtml(record.initials)}</span><span class="person-copy"><strong>${escapeHtml(record.customer)}</strong>${record.subtitle ? `<small>${escapeHtml(record.subtitle)}</small>` : ''}</span></div>`;
}

function rowMarkup(record, view) {
  const amount = view === 'customers' ? money.format(record.amount) : money.format(record.amount);
  const customerHeading = view === 'customers' ? 'Client' : view === 'products' ? 'Désignation' : view === 'invoices' ? 'Tiers' : view === 'purchasing' ? 'Fournisseur' : 'Client';
  const dateHeading = view === 'products' ? 'Unité' : view === 'customers' ? 'Localisation' : 'Date';
  return `<tr data-ref="${escapeHtml(record.ref)}" data-search="${escapeHtml(`${record.ref} ${record.customer} ${record.status} ${record.owner} ${record.subtitle ?? ''}`.toLocaleLowerCase('fr'))}">
    <td><span class="table-ref">${escapeHtml(record.ref)}</span></td>
    <td>${personCell(record)}</td>
    <td>${escapeHtml(record.date)}</td>
    <td><span class="status-pill status-${escapeHtml(record.tone)}">${escapeHtml(record.status)}</span></td>
    <td class="amount">${amount}</td>
    <td>${escapeHtml(record.owner)}</td>
  </tr>`;
}

function tableMarkup(view, { compact = false } = {}) {
  const config = viewConfig[view];
  const items = state[view] ?? [];
  const filtered = items.filter((item) => {
    const matchesFilter = state.filter === 'Tous' || item.status === state.filter;
    const searchable = `${item.ref} ${item.customer} ${item.status} ${item.owner} ${item.subtitle ?? ''}`.toLocaleLowerCase('fr');
    return matchesFilter && searchable.includes(state.search.toLocaleLowerCase('fr'));
  });
  const visible = compact ? filtered.slice(0, 4) : filtered;
  const customerHeading = view === 'customers' ? 'Client' : view === 'products' ? 'Désignation' : view === 'invoices' ? 'Tiers' : view === 'purchasing' ? 'Fournisseur' : 'Client';
  const dateHeading = view === 'products' ? 'Unité' : view === 'customers' ? 'Localisation' : view === 'invoices' ? 'Échéance' : 'Date';

  return `<div class="table-panel panel">
    ${compact ? '' : `<div class="table-toolbar"><div class="filter-tabs" role="group" aria-label="Filtrer ${escapeHtml(config.title.toLowerCase())}">${config.filters.map((filter) => `<button class="filter-tab ${state.filter === filter ? 'is-selected' : ''}" data-filter="${escapeHtml(filter)}">${escapeHtml(filter)}</button>`).join('')}</div><label class="inline-search"><span aria-hidden="true">⌕</span><input class="table-search" type="search" placeholder="Filtrer les résultats" aria-label="Filtrer les résultats" value="${escapeHtml(state.search)}"></label></div>`}
    <div class="table-scroll"><table><thead><tr><th>${escapeHtml(config.ref)}</th><th>${customerHeading}</th><th>${dateHeading}</th><th>État</th><th>${escapeHtml(config.amount)}</th><th>${escapeHtml(config.owner)}</th></tr></thead>
      <tbody>${visible.length ? visible.map((record) => rowMarkup(record, view)).join('') : `<tr><td colspan="6" class="table-empty">Aucun résultat pour cette recherche.</td></tr>`}</tbody>
    </table></div>
    ${compact ? '' : `<div class="table-summary"><span>${filtered.length} résultat${filtered.length > 1 ? 's' : ''}</span><span>Données de démonstration</span></div>`}
  </div>`;
}

function dashboardMarkup() {
  return `<section class="welcome-band"><div class="welcome-copy"><p class="eyebrow">MARDI 13 OCTOBRE 2026 · VOTRE ACTIVITÉ</p><h1>Bonjour Claire,</h1><p>Voici ce qui se passe chez Maison Lenoir aujourd'hui.</p></div><div class="welcome-aside"><span class="welcome-spark" aria-hidden="true">✳</span><div class="welcome-stat"><strong>+12,8 %</strong><span>par rapport au mois dernier</span></div></div></section>
    <section class="metric-grid" aria-label="Indicateurs clés">
      <article class="metric-card"><div class="metric-top"><span>Chiffre d'affaires · octobre</span><span class="metric-mark">↗</span></div><div class="metric-value">38 450 € <span class="metric-change">+8,4 %</span></div><div class="metric-foot">vs. 35 460 € en septembre</div></article>
      <article class="metric-card"><div class="metric-top"><span>Commandes en cours</span><span class="metric-mark">↗</span></div><div class="metric-value">24 <span class="metric-change">+3</span></div><div class="metric-foot">6 commandes à préparer</div></article>
      <article class="metric-card"><div class="metric-top"><span>À encaisser</span><span class="metric-mark">€</span></div><div class="metric-value">21 480 € <span class="metric-change">−4,2 %</span></div><div class="metric-foot">4 factures au-delà de l'échéance</div></article>
      <article class="metric-card"><div class="metric-top"><span>Devis à relancer</span><span class="metric-mark">↻</span></div><div class="metric-value">8 <span class="metric-change">2 urgents</span></div><div class="metric-foot">12 480 € de potentiel commercial</div></article>
    </section>

    <section class="dashboard-grid">
      <article class="panel chart-panel"><header class="panel-header"><div><h2>Ventes réalisées</h2><p>Évolution du chiffre d'affaires · 6 derniers mois</p></div><div class="chart-key"><span><i></i>Cette année</span><span><i></i>Année passée</span></div></header>
        <div class="chart-total"><strong>248 630 €</strong><span>↗ 12,8 %</span></div>
        <div class="chart" aria-label="Graphique des ventes de mai à octobre"><div class="chart-column"><div class="chart-bars"><span class="chart-bar" style="height:53%"></span><span class="chart-bar current" style="height:62%"></span></div><small>Mai</small></div><div class="chart-column"><div class="chart-bars"><span class="chart-bar" style="height:61%"></span><span class="chart-bar current" style="height:70%"></span></div><small>Juin</small></div><div class="chart-column"><div class="chart-bars"><span class="chart-bar" style="height:48%"></span><span class="chart-bar current" style="height:75%"></span></div><small>Juil.</small></div><div class="chart-column"><div class="chart-bars"><span class="chart-bar" style="height:72%"></span><span class="chart-bar current" style="height:66%"></span></div><small>Août</small></div><div class="chart-column"><div class="chart-bars"><span class="chart-bar" style="height:63%"></span><span class="chart-bar current" style="height:82%"></span></div><small>Sept.</small></div><div class="chart-column"><div class="chart-bars"><span class="chart-bar" style="height:57%"></span><span class="chart-bar current" style="height:91%"></span></div><small>Oct.</small></div></div>
        <div class="chart-note"><span>Objectif mensuel : <strong>42 000 €</strong></span><span>Dernière mise à jour : aujourd'hui</span></div>
      </article>
      <article class="panel"><header class="panel-header"><div><h2>À suivre</h2><p>Les prochaines échéances</p></div><button class="text-button" data-view="invoices">Tout voir →</button></header>
        <div class="agenda-list"><div class="agenda-item"><span class="agenda-date"><strong>14</strong><small>oct.</small></span><span class="agenda-copy"><strong>Relancer Maison Ravel</strong><small>Devis DEV-0208 · expire demain</small></span><span class="agenda-amount">6 240 €</span></div><div class="agenda-item"><span class="agenda-date"><strong>15</strong><small>oct.</small></span><span class="agenda-copy"><strong>Échéance Studio Orme</strong><small>Facture FAC-0887</small></span><span class="agenda-amount">960 €</span></div><div class="agenda-item"><span class="agenda-date"><strong>16</strong><small>oct.</small></span><span class="agenda-copy"><strong>Réception Bois & Matières</strong><small>Commande ACH-0126 · 4 lignes</small></span><span class="agenda-amount">4 820 €</span></div></div>
        <div class="agenda-footer"><button class="text-button" data-view="quotes">Ouvrir les relances →</button></div>
      </article>
    </section>

    <section class="panel table-panel"><header class="panel-header"><div><h2>Commandes récentes</h2><p>Les dernières opérations de votre équipe</p></div><button class="text-button" data-view="orders">Toutes les commandes →</button></header>${tableMarkup('orders', { compact: true })}</section>

    <section class="lower-strip" style="margin-top: 15px"><article class="panel"><header class="panel-header"><div><h2>Stocks à surveiller</h2><p>Seuils d'alerte · dépôt principal</p></div><button class="text-button" data-view="stock">Voir le stock →</button></header><div class="stock-list"><div class="stock-row"><span class="stock-product"><strong>Lampe Noro</strong><small>LU-0088 · seuil : 6 unités</small></span><span class="stock-track"><span class="low" style="width:28%"></span></span><span class="stock-value">3</span></div><div class="stock-row"><span class="stock-product"><strong>Vase Dune</strong><small>VA-0102 · seuil : 4 unités</small></span><span class="stock-track"><span class="low" style="width:5%"></span></span><span class="stock-value">0</span></div><div class="stock-row"><span class="stock-product"><strong>Chaise Alba</strong><small>CH-0142 · seuil : 8 unités</small></span><span class="stock-track"><span style="width:68%"></span></span><span class="stock-value">24</span></div></div></article>
      <article class="panel alert-panel"><header class="alert-header"><h2>Points d'attention</h2><span class="alert-number">3</span></header><div class="alert-item"><span class="alert-symbol">!</span><span><strong>2 devis expirent bientôt</strong><small>Plus que 48 h pour les relancer</small></span></div><div class="alert-item"><span class="alert-symbol">↗</span><span><strong>4 factures en retard</strong><small>Montant total : 5 280 €</small></span></div><div class="alert-item"><span class="alert-symbol">↓</span><span><strong>2 références sous le seuil</strong><small>Vérifier les commandes fournisseurs</small></span></div></article></section>`;
}

function listMarkup(view) {
  const config = viewConfig[view];
  return `<section class="list-page"><header class="page-heading"><div><p class="eyebrow">${config.eyebrow}</p><h1>${config.title}</h1><p class="page-subtitle">${config.subtitle}</p></div><div class="heading-actions"><button class="button button-secondary" data-action="export"><span class="button-mark" aria-hidden="true">↓</span>Exporter</button><button class="button button-primary" data-action="create"><span class="button-mark" aria-hidden="true">+</span>${config.button}</button></div></header>
    <div class="view-summary">${config.summary.map((item, index) => `<span><i class="summary-dot ${index === 1 ? 'orange' : index === 2 ? 'blue' : ''}"></i>${escapeHtml(item)}</span>`).join('')}</div>
    ${tableMarkup(view)}</section>`;
}

function stockMarkup() {
  const rows = state.stock.filter((record) => {
    const matchesFilter = state.filter === 'Tous' || record.status === state.filter;
    return matchesFilter && `${record.ref} ${record.customer} ${record.status} ${record.date}`.toLocaleLowerCase('fr').includes(state.search.toLocaleLowerCase('fr'));
  });
  return `<section class="list-page"><header class="page-heading"><div><p class="eyebrow">LOGISTIQUE · DISPONIBILITÉ</p><h1>État des stocks</h1><p class="page-subtitle">Quantités physiques, réservées et disponibles par dépôt.</p></div><div class="heading-actions"><button class="button button-secondary" data-action="export"><span class="button-mark">↓</span>Exporter</button><button class="button button-primary" data-action="create"><span class="button-mark">+</span>Ajuster le stock</button></div></header>
    <div class="view-summary"><span><i class="summary-dot"></i>126 références suivies</span><span><i class="summary-dot orange"></i>2 sous le seuil</span><span><i class="summary-dot blue"></i>2 dépôts</span></div>
    <div class="table-panel panel"><div class="table-toolbar"><div class="filter-tabs" role="group" aria-label="Filtrer le stock">${['Tous', 'Disponible', 'Stock bas', 'Rupture'].map((filter) => `<button class="filter-tab ${state.filter === filter ? 'is-selected' : ''}" data-filter="${filter}">${filter}</button>`).join('')}</div><label class="inline-search"><span aria-hidden="true">⌕</span><input class="table-search" type="search" placeholder="Filtrer les références" aria-label="Filtrer les références" value="${escapeHtml(state.search)}"></label></div>
      <div class="table-scroll"><table><thead><tr><th>Référence</th><th>Produit</th><th>Dépôt</th><th>État</th><th>Physique</th><th>Seuil</th></tr></thead><tbody>${rows.length ? rows.map((record) => `<tr data-ref="${record.ref}" data-search="${record.customer.toLocaleLowerCase('fr')}"><td><span class="table-ref">${record.ref}</span></td><td>${personCell(record)}</td><td>${record.date}</td><td><span class="status-pill status-${record.tone}">${record.status}</span></td><td class="amount">${record.amount} u.</td><td>${record.owner}</td></tr>`).join('') : '<tr><td colspan="6" class="table-empty">Aucun résultat pour cette recherche.</td></tr>'}</tbody></table></div><div class="table-summary"><span>${rows.length} référence${rows.length > 1 ? 's' : ''}</span><span>Quantités fictives · aucun mouvement réel</span></div></div></section>`;
}

function render() {
  sectionName.textContent = labels[state.view];
  document.querySelectorAll('[data-view]').forEach((element) => {
    element.classList.toggle('is-active', element.dataset.view === state.view && element.classList.contains('nav-item'));
  });
  appContent.innerHTML = state.view === 'dashboard' ? dashboardMarkup() : state.view === 'stock' ? stockMarkup() : listMarkup(state.view);
  const tableSearch = document.querySelector('.table-search');
  if (tableSearch) tableSearch.addEventListener('input', (event) => {
    state.search = event.target.value;
    const position = event.target.selectionStart;
    render();
    const replacement = document.querySelector('.table-search');
    replacement?.focus();
    replacement?.setSelectionRange(position, position);
  });
}

function showToast(message) {
  toast.textContent = message;
  toast.classList.add('is-visible');
  window.clearTimeout(showToast.timer);
  showToast.timer = window.setTimeout(() => toast.classList.remove('is-visible'), 2800);
}

function createRecord(view, values) {
  const config = viewConfig[view];
  const names = { quotes: 'DEV', orders: 'CMD', customers: 'CLI', products: 'REF', invoices: 'FAC', purchasing: 'ACH', stock: 'MVT' };
  const list = state[view] ?? (state.stock = []);
  const number = String(209 + list.length).padStart(4, '0');
  const customer = values.name.trim();
  const initials = customer.split(/\s+/).slice(0, 2).map((part) => part[0]?.toUpperCase() ?? '').join('');
  const record = {
    ref: `${names[view]}-2026-${number}`,
    customer,
    initials: initials || 'ML',
    subtitle: view === 'customers' ? values.contact.trim() || 'Nouveau compte' : undefined,
    date: new Intl.DateTimeFormat('fr-FR', { day: 'numeric', month: 'short', year: 'numeric' }).format(new Date()),
    amount: Number(values.amount) || 0,
    status: view === 'quotes' ? 'Brouillon' : view === 'customers' || view === 'products' ? 'Actif' : view === 'stock' ? 'À vérifier' : 'En attente',
    tone: view === 'quotes' ? 'gray' : view === 'stock' ? 'orange' : 'green',
    owner: view === 'customers' ? 'Net 30 jours' : view === 'products' ? '0 unité' : view === 'stock' ? 'Seuil : 4' : 'Claire Martin',
    avatar: 'blue',
  };
  list.unshift(record);
  state.filter = 'Tous';
  state.search = '';
  state.view = view === 'stock' ? 'stock' : view;
  render();
  showToast(`${config?.title ?? 'Stock'} · « ${customer} » ajouté à la démonstration.`);
}

function openCreateDialog() {
  const view = state.view;
  const config = viewConfig[view];
  const isCustomer = view === 'customers';
  const isProduct = view === 'products';
  const isStock = view === 'stock';
  const isInvoice = view === 'invoices';
  const isPurchasing = view === 'purchasing';
  const isOrder = view === 'orders';
  const isQuote = view === 'quotes';
  const itemName = isCustomer ? 'client' : isProduct ? 'produit' : isStock ? 'ajustement' : isInvoice ? 'facture' : isPurchasing ? 'achat fournisseur' : isOrder ? 'commande' : 'devis';
  const nameLabel = isCustomer ? 'Nom du client' : isProduct ? 'Nom du produit' : isStock ? 'Produit concerné' : isPurchasing ? 'Fournisseur' : isInvoice ? 'Client à facturer' : 'Nom du client';
  dialogContent.innerHTML = `<p class="dialog-eyebrow">DÉMONSTRATION · ${escapeHtml(labels[view].toUpperCase())}</p><h2>${escapeHtml(config?.button ?? 'Nouvelle opération')}</h2><p class="dialog-description">Ajoutez un ${itemName} fictif. Cette action reste dans le navigateur et n’enregistre aucune donnée dans une base.</p>
    <form id="create-form" class="dialog-form"><label class="field-label">${nameLabel}<input name="name" required maxlength="80" placeholder="Ex. Atelier des Tilleuls" autocomplete="off"></label>
    ${!isCustomer && !isStock ? `<label class="field-label">${isProduct ? 'Prix unitaire indicatif' : 'Montant estimé (€)'}<input name="amount" type="number" min="0" step="1" value="${isProduct ? '120' : '1450'}" required></label>` : ''}
    ${isCustomer ? '<label class="field-label">E-mail de contact<input name="contact" type="email" placeholder="contact@exemple.fr"></label>' : ''}
    ${isStock ? '<label class="field-label">Quantité constatée<input name="amount" type="number" min="0" step="1" value="0" required></label>' : ''}
    <div class="dialog-actions"><button type="button" class="button button-secondary" data-action="close-dialog">Annuler</button><button class="button button-primary" type="submit">Ajouter à la démo</button></div></form>`;
  dialog.showModal();
  dialog.querySelector('[name="name"]')?.focus();
}

function openRecordDialog(reference) {
  const view = state.view === 'dashboard' ? 'orders' : state.view;
  const records = state[view] ?? [];
  const record = records.find((item) => item.ref === reference);
  if (!record) return;
  dialogContent.innerHTML = `<p class="dialog-eyebrow">FICHE · ${escapeHtml(labels[view]?.toUpperCase() ?? 'DÉTAIL')}</p><h2>${escapeHtml(record.customer)}</h2><p class="dialog-description">${escapeHtml(record.ref)} · donnée de démonstration</p><div class="detail-grid"><span class="detail-pair"><small>État</small><strong>${escapeHtml(record.status)}</strong></span><span class="detail-pair"><small>Montant</small><strong>${money.format(record.amount)}</strong></span><span class="detail-pair"><small>Date</small><strong>${escapeHtml(record.date)}</strong></span><span class="detail-pair"><small>Responsable</small><strong>${escapeHtml(record.owner)}</strong></span></div><p class="detail-note">Les détails métier, permissions et transitions réelles seront raccordés aux services Oracle / ORDS après validation de l’architecture.</p><div class="dialog-actions"><button class="button button-secondary" data-action="close-dialog">Fermer</button></div>`;
  dialog.showModal();
}

document.addEventListener('click', (event) => {
  const viewButton = event.target.closest('[data-view]');
  if (viewButton) {
    state.view = viewButton.dataset.view;
    state.filter = 'Tous';
    state.search = '';
    searchInput.value = '';
    render();
    return;
  }

  const filterButton = event.target.closest('[data-filter]');
  if (filterButton) {
    state.filter = filterButton.dataset.filter;
    render();
    return;
  }

  const action = event.target.closest('[data-action]')?.dataset.action;
  if (action === 'create') openCreateDialog();
  if (action === 'close-dialog') dialog.close();
  if (action === 'export') showToast('Export de démonstration : le fichier sera disponible après connexion aux données.');

  const row = event.target.closest('tr[data-ref]');
  if (row) openRecordDialog(row.dataset.ref);
});

document.addEventListener('submit', (event) => {
  if (event.target.id !== 'create-form') return;
  event.preventDefault();
  createRecord(state.view, Object.fromEntries(new FormData(event.target)));
  dialog.close();
});

searchInput.addEventListener('input', () => {
  state.search = searchInput.value;
  render();
});

document.addEventListener('keydown', (event) => {
  if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
    event.preventDefault();
    searchInput.focus();
  }
  if (event.key === 'Escape' && dialog.open) dialog.close();
});

dialog.addEventListener('click', (event) => {
  if (event.target === dialog) dialog.close();
});

render();