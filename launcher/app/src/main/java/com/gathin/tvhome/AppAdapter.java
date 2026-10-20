package com.gathin.tvhome;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.content.res.Resources;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Rect;
import android.graphics.drawable.Drawable;
import android.provider.Settings;
import android.util.DisplayMetrics;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

public class AppAdapter extends RecyclerView.Adapter<AppAdapter.CategoryHolder> {

    public interface TileListener {
        void onTileFocused(Entry entry, View card, int row, int col);
        void onRowScrolled(int dx);
        boolean onTopEdgeReached();
    }

    public static final class Entry {
        static final int APP = 0, HOME_SETTINGS = 1, CARD = 2;

        final int kind;
        final String label;
        final ComponentName component;
        final String pkg;
        final Drawable banner;
        final Drawable icon;
        final String name;
        final boolean isLeanback;
        int ambient;

        Entry(String label, ComponentName component, Drawable banner, Drawable icon, boolean isLeanback) {
            this(APP, label, component, banner, icon, null, 0, isLeanback);
        }

        Entry(int kind, String label, ComponentName component, Drawable banner, Drawable icon, String caption, int accent, boolean isLeanback) {
            this.kind = kind;
            this.label = label;
            this.component = component;
            this.pkg = component != null ? component.getPackageName() : "";
            this.banner = banner;
            this.icon = icon;
            this.name = caption == null ? label : label + " \u00B7 " + caption;
            this.ambient = accent;
            this.isLeanback = isLeanback;
        }
    }

    public static final class Category {
        public final String id;
        public final String title;
        public final List<Entry> apps;

        public Category(String id, String title, List<Entry> apps) {
            this.id = id;
            this.title = title;
            this.apps = apps;
        }
    }

    static final float FOCUS_SCALE = 1.10f;
    static final float DESIGN_W_DP = 186f;

    static float cornerRadius(int tileWidthPx, float density) {
        return 14f * density;
    }

    private final Context ctx;
    private final TileListener listener;
    private final int dockSize;
    private final List<String> favourites;
    private final Set<String> hidden;
    private final boolean animations;
    private final boolean advancedEffects;
    private final boolean showHomeSettings;
    private final boolean reducedMotion;
    private final List<Category> categories = new ArrayList<>();
    private final RecyclerView.RecycledViewPool sharedPool = new RecyclerView.RecycledViewPool();

    public AppAdapter(Context ctx, TileListener listener, int dockSize, Config cfg) {
        this.ctx = ctx;
        this.listener = listener;
        this.dockSize = dockSize;
        this.favourites = cfg.dockApps;
        this.hidden = new HashSet<>(cfg.hiddenApps);
        this.animations = cfg.animations;
        this.advancedEffects = cfg.animations && cfg.advancedEffects;
        this.showHomeSettings = cfg.showHomeSettingsShortcut;
        this.reducedMotion = cfg.reducedMotion;
        setHasStableIds(true);
    }

    @Override
    public long getItemId(int position) {
        return categories.get(position).id.hashCode();
    }

    @Override
    public int getItemCount() {
        return categories.size();
    }

    @NonNull
    @Override
    public CategoryHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_category_row, parent, false);
        return new CategoryHolder(v);
    }

    @Override
    public void onBindViewHolder(@NonNull CategoryHolder holder, int position) {
        Category cat = categories.get(position);
        holder.title.setText(cat.title);

        LinearLayoutManager lm = new LinearLayoutManager(ctx, LinearLayoutManager.HORIZONTAL, false);
        holder.recycler.setLayoutManager(lm);
        holder.recycler.setRecycledViewPool(sharedPool);
        holder.recycler.setHasFixedSize(true);
        HorizontalAppAdapter appAdapter = new HorizontalAppAdapter(ctx, cat.apps, position, listener,
                animations, advancedEffects, reducedMotion);
        holder.recycler.setAdapter(appAdapter);

        holder.recycler.clearOnScrollListeners();
        holder.recycler.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrolled(@NonNull RecyclerView rv, int dx, int dy) {
                if (listener != null) {
                    listener.onRowScrolled(dx);
                }
            }
        });
    }

    public float focusScale() {
        return FOCUS_SCALE;
    }

    public List<Category> getCategories() {
        return categories;
    }

    public int[] findAppPosition(String key) {
        if (key == null) return null;
        for (int r = 0; r < categories.size(); r++) {
            List<Entry> apps = categories.get(r).apps;
            for (int c = 0; c < apps.size(); c++) {
                Entry e = apps.get(c);
                String k = e.component != null ? e.component.flattenToShortString() : e.pkg;
                if (key.equals(k)) {
                    return new int[]{r, c};
                }
            }
        }
        return null;
    }

    public String keyAt(int row, int col) {
        if (row >= 0 && row < categories.size()) {
            List<Entry> apps = categories.get(row).apps;
            if (col >= 0 && col < apps.size()) {
                Entry e = apps.get(col);
                return e.component != null ? e.component.flattenToShortString() : e.pkg;
            }
        }
        return null;
    }

    public Entry entryAt(int row, int col) {
        if (row >= 0 && row < categories.size()) {
            List<Entry> apps = categories.get(row).apps;
            if (col >= 0 && col < apps.size()) {
                return apps.get(col);
            }
        }
        return null;
    }

    void reload(List<Cards.Card> cards) {
        PackageManager pm = ctx.getPackageManager();
        Intent probe = new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LEANBACK_LAUNCHER);
        List<ResolveInfo> found = pm.queryIntentActivities(probe, 0);
        Map<String, Cards.Card> cardByPkg = new HashMap<>();
        for (Cards.Card c : cards) cardByPkg.put(c.pkg, c);

        List<Entry> fresh = new ArrayList<>();
        Set<String> seenPkgs = new HashSet<>();
        for (ResolveInfo ri : found) {
            if (ri.activityInfo == null) continue;
            String pkg = ri.activityInfo.packageName;
            if (pkg.equals(ctx.getPackageName()) || hidden.contains(pkg)) continue;
            seenPkgs.add(pkg);
            ComponentName component = new ComponentName(pkg, ri.activityInfo.name);
            Cards.Card card = cardByPkg.get(pkg);
            if (card != null && !card.component.equals(component)) continue;
            Drawable banner = loadBanner(pm, ri);
            Drawable icon = ri.loadIcon(pm);
            if (card != null) {
                fresh.add(new Entry(Entry.CARD, card.label, component, banner, icon, card.caption, card.accent, true));
            } else {
                fresh.add(new Entry(Cards.cleanLabel(String.valueOf(ri.loadLabel(pm)), pkg), component, banner, icon, true));
            }
        }

        // TV Box support: discover standard mobile apps that don't declare LEANBACK_LAUNCHER
        Intent standardProbe = new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER);
        List<ResolveInfo> standardApps = pm.queryIntentActivities(standardProbe, 0);
        for (ResolveInfo ri : standardApps) {
            if (ri.activityInfo == null) continue;
            String pkg = ri.activityInfo.packageName;
            if (pkg.equals(ctx.getPackageName()) || hidden.contains(pkg) || seenPkgs.contains(pkg)) continue;
            seenPkgs.add(pkg);
            ComponentName component = new ComponentName(pkg, ri.activityInfo.name);
            Drawable banner = loadBanner(pm, ri);
            Drawable icon = ri.loadIcon(pm);
            fresh.add(new Entry(Cards.cleanLabel(String.valueOf(ri.loadLabel(pm)), pkg), component, banner, icon, false));
        }

        // 1. Group Dock Favorites
        List<Entry> dockList = new ArrayList<>();
        Set<String> dockPkgs = new HashSet<>(favourites);
        for (Entry e : fresh) {
            if (dockPkgs.contains(e.pkg)) {
                dockList.add(e);
            }
        }
        Collections.sort(dockList, (a, b) -> {
            int fa = favourites.indexOf(a.pkg), fb = favourites.indexOf(b.pkg);
            return Integer.compare(fa, fb);
        });

        // 2. Group Categories
        List<Entry> streaming = new ArrayList<>();
        List<Entry> games = new ArrayList<>();
        List<Entry> tools = new ArrayList<>();
        List<Entry> system = new ArrayList<>();

        for (Entry e : fresh) {
            int cat = detectCategory(e.pkg, e.label);
            if (cat == 1) streaming.add(e);
            else if (cat == 2) games.add(e);
            else if (cat == 3) tools.add(e);
            else system.add(e);
        }

        Collections.sort(streaming, (a, b) -> a.label.compareToIgnoreCase(b.label));
        Collections.sort(games, (a, b) -> a.label.compareToIgnoreCase(b.label));
        Collections.sort(tools, (a, b) -> a.label.compareToIgnoreCase(b.label));
        Collections.sort(system, (a, b) -> a.label.compareToIgnoreCase(b.label));

        if (showHomeSettings && pm.resolveActivity(new Intent(Settings.ACTION_HOME_SETTINGS), 0) != null) {
            system.add(new Entry(Entry.HOME_SETTINGS, ctx.getString(R.string.home_settings),
                    new ComponentName(ctx, HomeSettingsActivity.class), null,
                    ctx.getDrawable(R.drawable.ic_home_settings), null, 0, false));
        }

        categories.clear();
        if (!dockList.isEmpty()) {
            categories.add(new Category("favorites", ctx.getString(R.string.category_favorites), dockList));
        }
        if (!streaming.isEmpty()) {
            categories.add(new Category("streaming", ctx.getString(R.string.category_streaming), streaming));
        }
        if (!games.isEmpty()) {
            categories.add(new Category("games", ctx.getString(R.string.category_games), games));
        }
        if (!tools.isEmpty()) {
            categories.add(new Category("tools", ctx.getString(R.string.category_tools), tools));
        }
        if (!system.isEmpty()) {
            categories.add(new Category("system", ctx.getString(R.string.category_system), system));
        }

        notifyDataSetChanged();
    }

    static int detectCategory(String pkg, String label) {
        String p = (pkg + " " + label).toLowerCase(Locale.ROOT);
        // 1. Streaming & Cine
        if (p.contains("netflix") || p.contains("youtube") || p.contains("prime") || p.contains("amazon")
                || p.contains("kodi") || p.contains("film") || p.contains("pollito") || p.contains("latino")
                || p.contains("iptv") || p.contains("magis") || p.contains("stremio") || p.contains("vlc")
                || p.contains("player") || p.contains("tv") || p.contains("video") || p.contains("cinema")
                || p.contains("movie") || p.contains("disney") || p.contains("max") || p.contains("hbo")
                || p.contains("star") || p.contains("directv") || p.contains("plex") || p.contains("pluto")
                || p.contains("crunchyroll") || p.contains("twitch") || p.contains("videomanager")
                || p.contains("dgplayer") || p.contains("earthcam") || p.contains("webvideo")
                || p.contains("fczx") || p.contains("zapptv")) {
            return 1;
        }
        // 2. Juegos y Emuladores
        if (p.contains("mupen") || p.contains("epsxe") || p.contains("gba") || p.contains("n64")
                || p.contains("snes") || p.contains("nes") || p.contains("retroarch") || p.contains("emulator")
                || p.contains("emu") || p.contains("game") || p.contains("juego") || p.contains("monopoly")
                || p.contains("playstation") || p.contains("psp") || p.contains("arcade") || p.contains("mame")
                || p.contains("fastemulator")) {
            return 2;
        }
        // 3. Herramientas y Navegación
        if (p.contains("downloader") || p.contains("zarchiver") || p.contains("estrongs") || p.contains("file")
                || p.contains("archiver") || p.contains("aptoide") || p.contains("airscreen") || p.contains("cast")
                || p.contains("browser") || p.contains("chrome") || p.contains("sbrowser") || p.contains("navegador")
                || p.contains("telegram") || p.contains("speedtest") || p.contains("cleaner") || p.contains("remote")
                || p.contains("drive") || p.contains("dubox") || p.contains("happymod") || p.contains("bluetooth")
                || p.contains("poison") || p.contains("kingred") || p.contains("netxxus") || p.contains("titan")
                || p.contains("hydra")) {
            return 3;
        }
        // 4. Sistema
        return 4;
    }

    private Drawable loadBanner(PackageManager pm, ResolveInfo ri) {
        int id = ri.activityInfo.banner;
        if (id == 0) id = ri.activityInfo.applicationInfo.banner;
        if (id != 0) {
            try {
                Resources resources = pm.getResourcesForApplication(ri.activityInfo.applicationInfo);
                int density = Math.max(DisplayMetrics.DENSITY_XHIGH, ctx.getResources().getDisplayMetrics().densityDpi);
                return resources.getDrawableForDensity(id, density, null);
            } catch (PackageManager.NameNotFoundException | Resources.NotFoundException ignored) {
            }
        }
        return ri.activityInfo.loadBanner(pm);
    }

    public static int sampleBannerColor(Drawable live) {
        if (live == null) return 0xFF444444;
        Drawable d = live.getConstantState() != null ? live.getConstantState().newDrawable().mutate() : live;
        Rect saved = new Rect(d.getBounds());
        int n = 12;
        Bitmap bmp = Bitmap.createBitmap(n, n, Bitmap.Config.ARGB_8888);
        Canvas c = new Canvas(bmp);
        d.setBounds(0, 0, n, n);
        d.draw(c);
        d.setBounds(saved);
        float[] hsv = new float[3];
        int best = 0xFF444444;
        float bestScore = -1f;
        long r = 0, g = 0, b = 0;
        for (int y = 0; y < n; y++) {
            for (int x = 0; x < n; x++) {
                int p = bmp.getPixel(x, y);
                r += Color.red(p);
                g += Color.green(p);
                b += Color.blue(p);
                Color.colorToHSV(p, hsv);
                float score = hsv[1] * Math.min(1f, hsv[2] * 1.4f);
                if (score > bestScore) {
                    bestScore = score;
                    best = p;
                }
            }
        }
        bmp.recycle();
        if (bestScore < 0.25f) {
            int avg = Color.rgb((int) (r / (n * n)), (int) (g / (n * n)), (int) (b / (n * n)));
            Color.colorToHSV(avg, hsv);
            hsv[2] = Math.max(hsv[2], 0.55f);
            return Color.HSVToColor(hsv);
        }
        Color.colorToHSV(best, hsv);
        hsv[1] = Math.min(1f, hsv[1] * 1.1f);
        hsv[2] = Math.max(0.5f, hsv[2]);
        return Color.HSVToColor(hsv);
    }

    public static final class CategoryHolder extends RecyclerView.ViewHolder {
        public final TextView title;
        public final RecyclerView recycler;

        public CategoryHolder(View v) {
            super(v);
            title = v.findViewById(R.id.categoryTitle);
            recycler = v.findViewById(R.id.categoryRecycler);
        }
    }
}
