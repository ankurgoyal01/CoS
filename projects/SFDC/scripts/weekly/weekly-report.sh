#!/bin/bash
# weekly-report.sh — Ankur Goyal weekly GitHub performance report
# 8-week rolling · repo contributions · LOC added/removed · week-over-week
#
# Schedule: Monday 11:30 AM IST = 6:00 AM UTC
#   0 6 * * 1 /Users/agoyal/CoS/scripts/weekly/weekly-report.sh >> /Users/agoyal/CoS/logs/weekly-report.log 2>&1
#
# Prerequisites:
#   pip3 install reportlab matplotlib certifi
#   export GITHUB_TOKEN=your_enterprise_token   (from github.groupondev.com)
#   export ASANA_PAT=your_asana_token

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
LOGDIR="$HOME/CoS/logs"
REPORT_DIR="$HOME/CoS/logs/weekly-reports"
DATE=$(date +"%Y-%m-%d")
PDF_FILE="$REPORT_DIR/team-report-$DATE.pdf"

ASANA_TOKEN="${ASANA_PAT:-}"
ASANA_WORKSPACE="8437193015852"
ASANA_ASSIGNEE="1211542692184092"
GITHUB_ORG="sox-inscope salesforce"
GH_BASE="https://github.groupondev.com/api/v3"
NUM_WEEKS=8

mkdir -p "$LOGDIR" "$REPORT_DIR"

echo "========================================"
echo "Weekly report: last $NUM_WEEKS weeks"
echo "Generated: $DATE"
echo "PDF: $PDF_FILE"
echo "========================================"

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "ERROR: GITHUB_TOKEN not set."
  exit 1
fi

echo "Fetching $NUM_WEEKS weeks of GitHub data (this takes ~3-4 mins)..."

python3 << PYEOF
import json, urllib.request, urllib.error, ssl, certifi, time, io, os
from datetime import datetime, timedelta
from collections import defaultdict

# ── Setup ──────────────────────────────────────────────────────────────────────
ctx         = ssl.create_default_context(cafile=certifi.where())
gh_token    = os.environ.get("GITHUB_TOKEN", "")
orgs        = "$GITHUB_ORG".split()
org_query   = " ".join(f"org:{o}" for o in orgs)
pdf_file    = "$PDF_FILE"
report_date = "$DATE"
num_weeks   = int("$NUM_WEEKS")
gh_base     = "$GH_BASE"

TEAM = {
    "Ashwinkrishna": "akrishnam",
    "Niveditha":     "niver",
    "Nirajkumar":    "nshelke",
    "Kumar Ankit":   "kankit",
    "Amit":          "amipatil",
    "Ravi Kumar":    "kumarra",
    "Rakesh":        "rharidas",
    "Datta":         "dmaddala",
    "Ravindra":      "ravikumar",
}

# ── GitHub API helpers ─────────────────────────────────────────────────────────
def gh_get(url, accept="application/vnd.github+json"):
    req = urllib.request.Request(url, headers={
        "Authorization":        f"Bearer {gh_token}",
        "Accept":               accept,
        "X-GitHub-Api-Version": "2022-11-28",
    })
    try:
        with urllib.request.urlopen(req, context=ctx, timeout=15) as r:
            return json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        print(f"    API error {e.code}: {e.reason}")
        return {}
    except Exception as e:
        print(f"    API error: {e}")
        return {}

def gh_search_count(q):
    url = f"{gh_base}/search/issues?q={urllib.request.quote(q)}&per_page=1"
    d = gh_get(url)
    time.sleep(0.3)
    return d.get("total_count", 0)

def gh_search_items(q, per_page=100):
    url = f"{gh_base}/search/issues?q={urllib.request.quote(q)}&per_page={per_page}"
    d = gh_get(url)
    time.sleep(0.4)
    return d.get("items", [])

def gh_search_commits(q, per_page=30):
    url = f"{gh_base}/search/commits?q={urllib.request.quote(q)}&per_page={per_page}"
    d = gh_get(url, accept="application/vnd.github.cloak-preview+json")
    time.sleep(0.4)
    return d.get("items", [])

def get_commit_stats(repo_full, sha):
    url = f"{gh_base}/repos/{repo_full}/commits/{sha}"
    d = gh_get(url)
    time.sleep(0.3)
    stats = d.get("stats", {})
    return stats.get("additions", 0), stats.get("deletions", 0)

# ── Build week date ranges (Sun–Sat, oldest first) ────────────────────────────
def get_week_ranges(n):
    today = datetime.strptime(report_date, "%Y-%m-%d")
    days_since_sun = (today.weekday() + 1) % 7
    current_sun = today - timedelta(days=days_since_sun)
    ranges = []
    for i in range(n):
        start = current_sun - timedelta(weeks=i)
        end   = start + timedelta(days=6)
        end   = min(end, today)
        label = "This week" if i == 0 else f"W{n-i}"
        short = start.strftime("%b %d")
        ranges.append((start.strftime("%Y-%m-%d"), end.strftime("%Y-%m-%d"), label, short))
    return list(reversed(ranges))

weeks = get_week_ranges(num_weeks)
print("Week ranges:")
for s, e, lbl, _ in weeks:
    print(f"  {lbl}: {s} to {e}")

full_start = weeks[0][0]
full_end   = weeks[-1][1]

metrics      = ["prs_created", "prs_merged", "prs_reviewed", "comments"]
metric_labels = ["PRs Created", "PRs Merged", "PRs Reviewed", "Comments Given"]
names         = list(TEAM.keys())

# ── 1. Collect weekly PR metrics ──────────────────────────────────────────────
print("\n--- Fetching weekly PR metrics ---")
all_data = {name: [] for name in names}

for wi, (start, end, lbl, short) in enumerate(weeks):
    print(f"Fetching {lbl} ({start} to {end})...")
    for name, handle in TEAM.items():
        dr = f"{start}..{end}"
        prs_created  = gh_search_count(f"is:pr author:{handle} {org_query} created:{dr}")
        prs_merged   = gh_search_count(f"is:pr author:{handle} {org_query} merged:{dr}")
        prs_reviewed = gh_search_count(f"is:pr reviewed-by:{handle} {org_query} updated:{dr}")
        comments     = gh_search_count(f"is:pr commenter:{handle} {org_query} updated:{dr}")
        all_data[name].append({
            "prs_created": prs_created, "prs_merged": prs_merged,
            "prs_reviewed": prs_reviewed, "comments": comments,
        })
        print(f"  {name}: created={prs_created} merged={prs_merged} reviewed={prs_reviewed}")

# ── 2. Collect repo-wise contributions (full 8-week period) ───────────────────
print("\n--- Fetching repo-wise contributions ---")
repo_data = {}  # repo_data[name] = {repo: {created, merged}}

for name, handle in TEAM.items():
    print(f"  {name}...")
    dr = f"{full_start}..{full_end}"
    repo_data[name] = defaultdict(lambda: {"created": 0, "merged": 0})

    # PRs created — get items to extract repo names
    items_created = gh_search_items(
        f"is:pr author:{handle} {org_query} created:{dr}", per_page=100)
    for item in items_created:
        repo = item.get("repository_url", "").split("/repos/")[-1]
        if repo:
            repo_data[name][repo]["created"] += 1

    # PRs merged
    items_merged = gh_search_items(
        f"is:pr author:{handle} {org_query} merged:{dr}", per_page=100)
    for item in items_merged:
        repo = item.get("repository_url", "").split("/repos/")[-1]
        if repo:
            repo_data[name][repo]["merged"] += 1

# ── 3. Collect LOC added/removed per week (capped at 5 commits per dev/week) ──
print("\n--- Fetching lines of code (week over week) ---")
loc_data = {name: [] for name in names}  # loc_data[name][wi] = (added, removed)

for wi, (start, end, lbl, _) in enumerate(weeks):
    print(f"LOC {lbl}...")
    for name, handle in TEAM.items():
        dr      = f"{start}..{end}"
        commits = gh_search_commits(
            f"author:{handle} {org_query} author-date:{dr}", per_page=5)
        added = removed = 0
        for c in commits[:5]:
            repo_full = c.get("repository", {}).get("full_name", "")
            sha       = c.get("sha", "")
            if repo_full and sha:
                a, r = get_commit_stats(repo_full, sha)
                added   += a
                removed += r
        loc_data[name].append((added, removed))
        print(f"  {name}: +{added} -{removed}")

cur_week  = {n: all_data[n][-1] for n in names}
prev_week = {n: all_data[n][-2] for n in names}
week_shorts = [w[3] for w in weeks]

# ── PDF generation ─────────────────────────────────────────────────────────────
print("\n--- Generating PDF ---")

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle,
    Image as RLImage, PageBreak, HRFlowable, KeepTogether
)
from reportlab.lib.enums import TA_CENTER, TA_LEFT

doc = SimpleDocTemplate(pdf_file, pagesize=landscape(A4),
    leftMargin=1.5*cm, rightMargin=1.5*cm,
    topMargin=1.5*cm,  bottomMargin=1.5*cm)

styles = getSampleStyleSheet()
DARK  = colors.HexColor("#1a1a2e")
BLUE  = colors.HexColor("#378ADD")
TEAL  = colors.HexColor("#1D9E75")
AMBER = colors.HexColor("#EF9F27")
CORAL = colors.HexColor("#D85A30")
LGREY = colors.HexColor("#F1EFE8")
MGREY = colors.HexColor("#888780")
BGGRY = colors.HexColor("#F8F8F8")

def PS(name, **kw):
    return ParagraphStyle(name, parent=styles.get("Normal"), **kw)

title_s = PS("tt", fontSize=20, textColor=DARK,  spaceAfter=4,  alignment=TA_CENTER)
sub_s   = PS("ss", fontSize=10, textColor=MGREY, spaceAfter=14, alignment=TA_CENTER)
h2_s    = PS("hh", fontSize=12, textColor=DARK,  spaceBefore=10, spaceAfter=5,
             fontName="Helvetica-Bold")
small_s = PS("sm", fontSize=7,  textColor=MGREY, alignment=TA_CENTER)

def HR(): return HRFlowable(width="100%", thickness=1, color=BLUE, spaceAfter=10)
def SP(h=0.4): return Spacer(1, h*cm)

def header(title, subtitle):
    return [SP(0.3), Paragraph(title, title_s), Paragraph(subtitle, sub_s), HR()]

def tbl_style(header_color=DARK, font_size=9, alt=True):
    cmds = [
        ("BACKGROUND",    (0,0),  (-1,0),  header_color),
        ("TEXTCOLOR",     (0,0),  (-1,0),  colors.white),
        ("FONTNAME",      (0,0),  (-1,0),  "Helvetica-Bold"),
        ("FONTSIZE",      (0,0),  (-1,-1), font_size),
        ("ALIGN",         (0,0),  (-1,-1), "CENTER"),
        ("VALIGN",        (0,0),  (-1,-1), "MIDDLE"),
        ("GRID",          (0,0),  (-1,-1), 0.4, colors.HexColor("#cccccc")),
        ("ROWHEIGHT",     (0,0),  (-1,-1), 17),
        ("TOPPADDING",    (0,0),  (-1,-1), 3),
        ("BOTTOMPADDING", (0,0),  (-1,-1), 3),
    ]
    if alt:
        cmds.append(("ROWBACKGROUNDS",(0,1),(-1,-1),[LGREY, colors.white]))
    return TableStyle(cmds)

def delta_colour(tbl_style_cmds, row_i, col_i, diff):
    clr = TEAL if diff >= 0 else CORAL
    tbl_style_cmds += [
        ("TEXTCOLOR", (col_i,row_i),(col_i,row_i), clr),
        ("FONTNAME",  (col_i,row_i),(col_i,row_i), "Helvetica-Bold"),
    ]

def buf_to_img(buf, w, h):
    img = RLImage(buf, width=w*cm, height=h*cm)
    return img

story = []

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PAGE 1 — Team totals + current week breakdown
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
story += header(
    "Developer Performance Report",
    f"SFDC + GSOIT Engineering  ·  {num_weeks}-Week Rolling  ·  "
    f"{weeks[0][0]} to {weeks[-1][1]}  ·  Generated: {report_date}"
)

# Team totals table
tot_header = ["Metric"] + week_shorts + [f"{num_weeks}-Wk Total"]
tot_data   = [tot_header]
for m, lbl in zip(metrics, metric_labels):
    row   = [lbl]
    total = 0
    for wi in range(num_weeks):
        v = sum(all_data[n][wi][m] for n in names)
        row.append(str(v)); total += v
    row.append(str(total))
    tot_data.append(row)

cw_tot = [4.5*cm] + [2.2*cm]*num_weeks + [2.8*cm]
t = Table(tot_data, colWidths=cw_tot)
ts = tbl_style()
ts.add("BACKGROUND", (-1,1), (-1,-1), colors.HexColor("#E6F1FB"))
ts.add("FONTNAME",   (-1,1), (-1,-1), "Helvetica-Bold")
t.setStyle(ts)
story += [Paragraph("Team Totals — Rolling 8 Weeks", h2_s), t, SP()]

# Current week individual breakdown
story.append(Paragraph(
    f"Individual Breakdown — {weeks[-1][2]} ({weeks[-1][0]} to {weeks[-1][1]})", h2_s))
dh = ["Developer","PRs Created","PRs Merged","PRs Reviewed","Comments"]
dd = [dh] + [[n]+[str(cur_week[n][m]) for m in metrics] for n in names]
dt = Table(dd, colWidths=[5*cm,3.5*cm,3.5*cm,3.5*cm,3.5*cm])
dt.setStyle(tbl_style(header_color=BLUE))
story += [dt, PageBreak()]

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PAGE 2 — 8-week trend line charts (team totals)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
story += header("8-Week Team Trend",
    f"Team totals per week  ·  {weeks[0][0]} to {weeks[-1][1]}")

CHART_COLORS = ["#378ADD","#1D9E75","#EF9F27","#D85A30"]
x = list(range(num_weeks))

def trend_chart(metric, label, color):
    fig, ax = plt.subplots(figsize=(8.5, 3.0))
    y = [sum(all_data[n][wi][metric] for n in names) for wi in range(num_weeks)]
    ax.plot(x, y, marker="o", color=color, linewidth=2.2, markersize=6, zorder=3)
    ax.fill_between(x, y, alpha=0.12, color=color)
    for xi, yi in zip(x, y):
        ax.text(xi, yi + max(y, default=1)*0.05, str(yi),
                ha="center", va="bottom", fontsize=8, fontweight="bold")
    ax.set_xticks(x); ax.set_xticklabels(week_shorts, fontsize=8)
    ax.set_title(label, fontsize=11, fontweight="bold", pad=8)
    ax.yaxis.grid(True, linestyle="--", alpha=0.4, zorder=0)
    ax.set_axisbelow(True)
    ax.spines["top"].set_visible(False); ax.spines["right"].set_visible(False)
    ax.set_ylim(bottom=0)
    plt.tight_layout()
    buf = io.BytesIO()
    plt.savefig(buf, format="png", dpi=150, bbox_inches="tight")
    plt.close(); buf.seek(0)
    return buf

row_imgs = []
for (m, lbl), col in zip(zip(metrics, metric_labels), CHART_COLORS):
    img = buf_to_img(trend_chart(m, lbl, col), 13.5, 5)
    row_imgs.append(img)
    if len(row_imgs) == 2:
        t = Table([row_imgs], colWidths=[13.5*cm,13.5*cm])
        t.setStyle(TableStyle([("VALIGN",(0,0),(-1,-1),"TOP"),
                               ("LEFTPADDING",(0,0),(-1,-1),4),
                               ("RIGHTPADDING",(0,0),(-1,-1),4)]))
        story += [t, SP(0.3)]; row_imgs = []
story.append(PageBreak())

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PAGE 3 — Lines of code added/removed (week over week)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
story += header("Lines of Code — Week over Week",
    f"Additions and deletions per developer  ·  capped at 5 commits/dev/week")

# LOC trend chart — team total additions per week
def loc_trend_chart():
    fig, ax = plt.subplots(figsize=(17, 3.2))
    x_pos   = list(range(num_weeks))
    adds    = [sum(loc_data[n][wi][0] for n in names) for wi in range(num_weeks)]
    dels    = [sum(loc_data[n][wi][1] for n in names) for wi in range(num_weeks)]
    w       = 0.35
    ax.bar([xi - w/2 for xi in x_pos], adds, w, label="Lines added",   color="#1D9E75", alpha=0.85, zorder=3)
    ax.bar([xi + w/2 for xi in x_pos], dels, w, label="Lines removed", color="#D85A30", alpha=0.85, zorder=3)
    for xi, a, d in zip(x_pos, adds, dels):
        if a > 0: ax.text(xi-w/2, a+2, str(a), ha="center", va="bottom", fontsize=7)
        if d > 0: ax.text(xi+w/2, d+2, str(d), ha="center", va="bottom", fontsize=7)
    ax.set_xticks(x_pos); ax.set_xticklabels(week_shorts, fontsize=8)
    ax.set_title("Team LOC Added vs Removed per Week", fontsize=11, fontweight="bold", pad=8)
    ax.yaxis.grid(True, linestyle="--", alpha=0.4, zorder=0)
    ax.set_axisbelow(True)
    ax.spines["top"].set_visible(False); ax.spines["right"].set_visible(False)
    ax.set_ylim(bottom=0); ax.legend(fontsize=9)
    plt.tight_layout()
    buf = io.BytesIO()
    plt.savefig(buf, format="png", dpi=150, bbox_inches="tight")
    plt.close(); buf.seek(0)
    return buf

story += [buf_to_img(loc_trend_chart(), 27, 5.5), SP(0.4)]

# LOC per-developer table
story.append(Paragraph("Lines of Code by Developer — All 8 Weeks", h2_s))
loc_header = ["Developer"] + week_shorts + ["Total Added","Total Removed"]
loc_tdata  = [loc_header]
for name in names:
    row = [name]
    ta = tr = 0
    for wi in range(num_weeks):
        a, r = loc_data[name][wi]
        row.append(f"+{a}/-{r}")
        ta += a; tr += r
    row += [str(ta), str(tr)]
    loc_tdata.append(row)

cw_loc = [4*cm] + [2.4*cm]*num_weeks + [2.8*cm, 2.8*cm]
lt = Table(loc_tdata, colWidths=cw_loc)
ts_loc = tbl_style(font_size=8)
ts_loc.add("BACKGROUND", (-2,1), (-1,-1), colors.HexColor("#E6F1FB"))
ts_loc.add("FONTNAME",   (-2,1), (-1,-1), "Helvetica-Bold")
lt.setStyle(ts_loc)
story += [lt, SP(0.3),
          Paragraph("Note: LOC counts are sampled from up to 5 commits per developer per week via GitHub commit search.", small_s),
          PageBreak()]

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PAGE 4 — Per-developer 8-week grouped bar charts
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
story += header("Individual 8-Week Comparison",
    "PRs Created and PRs Reviewed per developer per week")

def dev_grouped_chart(metric, label):
    short_names = [n.split()[0] for n in names]
    n_devs = len(names)
    width  = 0.09
    fig, ax = plt.subplots(figsize=(15, 3.5))
    for di, (name, sn) in enumerate(zip(names, short_names)):
        vals   = [all_data[name][wi][metric] for wi in range(num_weeks)]
        offset = (di - n_devs/2 + 0.5) * width
        ax.bar([xi + offset for xi in range(num_weeks)], vals, width,
               label=sn, alpha=0.85, zorder=3)
    ax.set_xticks(list(range(num_weeks))); ax.set_xticklabels(week_shorts, fontsize=9)
    ax.set_title(label, fontsize=11, fontweight="bold", pad=8)
    ax.yaxis.grid(True, linestyle="--", alpha=0.4, zorder=0)
    ax.set_axisbelow(True)
    ax.spines["top"].set_visible(False); ax.spines["right"].set_visible(False)
    ax.set_ylim(bottom=0); ax.legend(fontsize=7, loc="upper right", ncol=3)
    plt.tight_layout()
    buf = io.BytesIO()
    plt.savefig(buf, format="png", dpi=150, bbox_inches="tight")
    plt.close(); buf.seek(0)
    return buf

for m, lbl in [("prs_created","PRs Created — Per Developer"),
               ("prs_reviewed","PRs Reviewed — Per Developer")]:
    story += [buf_to_img(dev_grouped_chart(m, lbl), 27, 6), SP(0.4)]
story.append(PageBreak())

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PAGE 5 — Repo-wise contributions (full 8-week period)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
story += header("Repository Contributions",
    f"PRs raised and merged per repo per developer  ·  {weeks[0][0]} to {weeks[-1][1]}")

for name in names:
    repos = repo_data[name]
    if not repos:
        story += [Paragraph(f"{name} — no repo data", h2_s), SP(0.2)]
        continue

    # Sort by total activity
    sorted_repos = sorted(repos.items(), key=lambda kv: kv[1]["created"]+kv[1]["merged"], reverse=True)
    # Shorten repo names: keep owner/repo
    rh = ["Repository", "PRs Raised", "PRs Merged", "Total"]
    rd = [rh]
    for repo, stats in sorted_repos[:15]:  # top 15 repos
        short_repo = "/".join(repo.split("/")[-2:]) if "/" in repo else repo
        total = stats["created"] + stats["merged"]
        rd.append([short_repo, str(stats["created"]), str(stats["merged"]), str(total)])

    cw_r = [9*cm, 3.5*cm, 3.5*cm, 3*cm]
    rt   = Table(rd, colWidths=cw_r)
    ts_r = tbl_style(header_color=TEAL, font_size=8)
    ts_r.add("ALIGN", (0,0), (0,-1), "LEFT")
    rt.setStyle(ts_r)
    story += [Paragraph(name, h2_s), rt, SP(0.3)]

story.append(PageBreak())

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PAGE 6 — Full 8-week detail tables with delta
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
story += header("8-Week Detail Tables",
    "All metrics by developer by week  ·  Δ = current week vs previous week")

for m, lbl in zip(metrics, metric_labels):
    story.append(Paragraph(lbl, h2_s))
    dh2   = ["Developer"] + week_shorts + ["Δ"]
    dd2   = [dh2]
    ts_cmds = []
    for name in names:
        row  = [name]
        for wi in range(num_weeks):
            row.append(str(all_data[name][wi][m]))
        diff = all_data[name][-1][m] - all_data[name][-2][m]
        row.append(f"+{diff}" if diff >= 0 else str(diff))
        dd2.append(row)

    cw2 = [4*cm] + [2.2*cm]*num_weeks + [2.2*cm]
    t2  = Table(dd2, colWidths=cw2)
    ts2 = tbl_style(font_size=8)

    extra = []
    for ri, name in enumerate(names, start=1):
        diff = all_data[name][-1][m] - all_data[name][-2][m]
        clr  = TEAL if diff >= 0 else CORAL
        extra += [("TEXTCOLOR",(-1,ri),(-1,ri), clr),
                  ("FONTNAME", (-1,ri),(-1,ri),"Helvetica-Bold")]
    for cmd in extra:
        ts2.add(*cmd)
    t2.setStyle(ts2)
    story += [t2, SP(0.4)]

story += [SP(0.5), Paragraph(
    f"Data: github.groupondev.com ({', '.join(orgs)})  ·  "
    f"Srilakshmi & Utkarsh excluded (non-coding roles)  ·  "
    f"LOC sampled ≤5 commits/dev/week  ·  Generated {report_date}",
    small_s)]

doc.build(story)
print(f"PDF generated: {pdf_file}")
PYEOF

if [ ! -f "$PDF_FILE" ]; then
  echo "ERROR: PDF was not generated."
  exit 1
fi
echo "PDF ready: $PDF_FILE"

# ── Create Asana task and attach PDF ─────────────────────────────────────────
if [ -z "$ASANA_TOKEN" ]; then
  echo "WARNING: ASANA_PAT not set — skipping Asana task."
  exit 0
fi

echo "Creating Asana task and attaching PDF..."

python3 << PYEOF
import json, urllib.request, ssl, certifi, os

ctx       = ssl.create_default_context(cafile=certifi.where())
token     = os.environ.get("ASANA_PAT", "$ASANA_TOKEN")
workspace = "$ASANA_WORKSPACE"
assignee  = "$ASANA_ASSIGNEE"
date_str  = "$DATE"
num_weeks = "$NUM_WEEKS"
pdf_file  = "$PDF_FILE"
task_name = f"Weekly GitHub Report — {num_weeks}-Week Rolling — {date_str}"

notes = (
    f"Auto-generated {num_weeks}-week rolling GitHub performance report\n"
    f"Generated: {date_str} (Monday morning run)\n\n"
    f"Report pages:\n"
    f"  1. Team totals rolling 8 weeks + current week individual breakdown\n"
    f"  2. 8-week trend line charts (team totals)\n"
    f"  3. Lines of code added/removed — week over week\n"
    f"  4. Per-developer grouped bar charts (PRs Created + Reviewed)\n"
    f"  5. Repository contributions — PRs raised & merged per repo\n"
    f"  6. Full 8-week detail tables with week-over-week delta\n\n"
    f"Team: Ashwinkrishna, Niveditha, Nirajkumar, Kumar Ankit, Amit, "
    f"Ravi Kumar, Rakesh, Datta, Ravindra\n\nPDF attached."
)

def api(url, data=None, method="POST", extra_headers=None):
    h = {"Authorization": f"Bearer {token}"}
    if extra_headers: h.update(extra_headers)
    if data and isinstance(data, dict):
        payload = json.dumps(data).encode()
        h["Content-Type"] = "application/json"
    else:
        payload = data
    req = urllib.request.Request(url, data=payload, method=method, headers=h)
    with urllib.request.urlopen(req, context=ctx) as r:
        return json.loads(r.read().decode())

result   = api("https://app.asana.com/api/1.0/tasks",
               {"data": {"name": task_name, "assignee": assignee,
                         "workspace": workspace, "due_on": date_str, "notes": notes}})
task_gid = result["data"]["gid"]
print(f"Task created: {task_name}")

with open(pdf_file, "rb") as f:
    pdf_bytes = f.read()

boundary = "----AsanaUploadBoundary7MA4YWxkTrZu0gW"
body = (
    f"--{boundary}\r\n"
    f'Content-Disposition: form-data; name="file"; '
    f'filename="team-report-{date_str}.pdf"\r\n'
    f"Content-Type: application/pdf\r\n\r\n"
).encode() + pdf_bytes + f"\r\n--{boundary}--\r\n".encode()

attach = api(
    f"https://app.asana.com/api/1.0/tasks/{task_gid}/attachments",
    data=body, method="POST",
    extra_headers={"Content-Type": f"multipart/form-data; boundary={boundary}"}
)
print(f"PDF attached: {attach.get('data',{}).get('gid','unknown')}")
print(f"Asana task: https://app.asana.com/0/0/{task_gid}/f")
PYEOF

echo "Done."
echo "========================================"
