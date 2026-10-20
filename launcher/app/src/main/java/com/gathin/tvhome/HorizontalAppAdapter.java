package com.gathin.tvhome;

import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.graphics.Outline;
import android.net.Uri;
import android.provider.Settings;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewOutlineProvider;
import android.view.animation.DecelerateInterpolator;
import android.view.animation.OvershootInterpolator;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.util.List;

public class HorizontalAppAdapter extends RecyclerView.Adapter<HorizontalAppAdapter.AppHolder> {

    private final Context ctx;
    private final List<AppAdapter.Entry> apps;
    private final int row;
    private final AppAdapter.TileListener listener;
    private final boolean animations;
    private final boolean advancedEffects;
    private final boolean reducedMotion;
    private final float density;

    public HorizontalAppAdapter(Context ctx, List<AppAdapter.Entry> apps, int row,
                                AppAdapter.TileListener listener,
                                boolean animations, boolean advancedEffects, boolean reducedMotion) {
        this.ctx = ctx;
        this.apps = apps;
        this.row = row;
        this.listener = listener;
        this.animations = animations;
        this.advancedEffects = advancedEffects;
        this.reducedMotion = reducedMotion;
        this.density = ctx.getResources().getDisplayMetrics().density;
        setHasStableIds(true);
    }

    @Override
    public long getItemId(int position) {
        AppAdapter.Entry e = apps.get(position);
        if (e.component != null) {
            return e.component.flattenToShortString().hashCode();
        }
        return e.label.hashCode();
    }

    @Override
    public int getItemCount() {
        return apps.size();
    }

    @NonNull
    @Override
    public AppHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_horizontal_app, parent, false);
        return new AppHolder(v);
    }

    @Override
    public void onBindViewHolder(@NonNull AppHolder h, int position) {
        AppAdapter.Entry e = apps.get(position);

        h.name.setText(e.name);
        boolean focused = h.card.isFocused();
        h.name.setAlpha(focused ? 1f : 0f);
        h.card.setScaleX(focused && animations ? AppAdapter.FOCUS_SCALE : 1f);
        h.card.setScaleY(focused && animations ? AppAdapter.FOCUS_SCALE : 1f);
        h.card.setTranslationZ(focused && advancedEffects ? 8f * density : 0f);

        if (e.banner != null) {
            h.banner.setImageDrawable(e.banner);
            h.banner.setVisibility(View.VISIBLE);
            h.icon.setVisibility(View.GONE);
            h.label.setVisibility(View.GONE);
        } else {
            h.banner.setImageDrawable(null);
            h.banner.setVisibility(View.GONE);
            h.icon.setImageDrawable(e.icon);
            h.icon.setVisibility(View.VISIBLE);
            h.label.setText(e.label);
            h.label.setVisibility(View.VISIBLE);
        }

        h.card.setOnClickListener(v -> launch(e));
        h.card.setOnLongClickListener(v -> {
            Intent i = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:" + e.pkg));
            i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            try {
                ctx.startActivity(i);
            } catch (ActivityNotFoundException ignored) {
            }
            return true;
        });

        h.card.setOnKeyListener((v, keyCode, event) -> {
            if (event.getAction() != KeyEvent.ACTION_DOWN) return false;
            if (keyCode == KeyEvent.KEYCODE_DPAD_UP && row == 0) {
                if (listener != null) {
                    return listener.onTopEdgeReached();
                }
            }
            return false;
        });

        h.card.setOnFocusChangeListener((view, isFocused) -> {
            view.animate().cancel();
            h.banner.animate().cancel();
            h.name.animate().cancel();

            float scale = !animations ? 1f : (advancedEffects ? 1.12f : AppAdapter.FOCUS_SCALE);
            float s = isFocused ? scale : 1f;

            if (!animations) {
                view.setScaleX(s);
                view.setScaleY(s);
                view.setTranslationZ(0f);
                h.banner.setScaleX(1f);
                h.banner.setScaleY(1f);
                h.name.setAlpha(isFocused ? 1f : 0f);
            } else if (reducedMotion) {
                view.animate().scaleX(s).scaleY(s)
                        .translationZ(isFocused && advancedEffects ? 8f * density : 0f)
                        .setDuration(isFocused ? 120 : 80)
                        .setInterpolator(new DecelerateInterpolator())
                        .withLayer().start();
                h.name.animate().alpha(isFocused ? 1f : 0f).setDuration(100).start();
            } else {
                view.animate().scaleX(s).scaleY(s)
                        .translationZ(isFocused && advancedEffects ? 8f * density : 0f)
                        .setDuration(advancedEffects ? (isFocused ? 220 : 170) : (isFocused ? 260 : 180))
                        .setInterpolator(new OvershootInterpolator(isFocused ? (advancedEffects ? 0.7f : 1.4f) : 0f))
                        .withLayer().start();
                if (advancedEffects) {
                    h.banner.animate().scaleX(isFocused ? 1.035f : 1f).scaleY(isFocused ? 1.035f : 1f)
                            .setDuration(280).start();
                }
                h.name.animate().alpha(isFocused ? 1f : 0f)
                        .translationY(isFocused ? density * 2f : -density * 4f)
                        .setDuration(220).start();
            }

            int pos = h.getBindingAdapterPosition();
            if (isFocused && listener != null && pos != RecyclerView.NO_POSITION) {
                listener.onTileFocused(e, view, row, pos);
            }
        });
    }

    private void launch(AppAdapter.Entry e) {
        if (e.kind == AppAdapter.Entry.HOME_SETTINGS) {
            ctx.startActivity(new Intent(ctx, HomeSettingsActivity.class)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
            return;
        }
        Intent intent;
        if (e.component != null) {
            intent = new Intent(Intent.ACTION_MAIN)
                    .setComponent(e.component)
                    .addCategory(e.isLeanback ? Intent.CATEGORY_LEANBACK_LAUNCHER : Intent.CATEGORY_LAUNCHER)
                    .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_RESET_TASK_IF_NEEDED);
        } else {
            intent = ctx.getPackageManager().getLaunchIntentForPackage(e.pkg);
        }
        if (intent == null) {
            Toast.makeText(ctx, ctx.getString(R.string.cant_open, e.name), Toast.LENGTH_SHORT).show();
            return;
        }
        try {
            ctx.startActivity(intent);
        } catch (ActivityNotFoundException | SecurityException ex) {
            Toast.makeText(ctx, ctx.getString(R.string.cant_open, e.name), Toast.LENGTH_SHORT).show();
        }
    }

    public static final class AppHolder extends RecyclerView.ViewHolder {
        final View card;
        final ImageView banner;
        final ImageView icon;
        final TextView label;
        final TextView name;

        AppHolder(View v) {
            super(v);
            card = v.findViewById(R.id.card);
            banner = v.findViewById(R.id.banner);
            icon = v.findViewById(R.id.icon);
            label = v.findViewById(R.id.label);
            name = v.findViewById(R.id.name);

            final float d = v.getResources().getDisplayMetrics().density;
            card.setOutlineProvider(new ViewOutlineProvider() {
                @Override
                public void getOutline(View view, Outline outline) {
                    outline.setRoundRect(0, 0, view.getWidth(), view.getHeight(), 14f * d);
                }
            });
            card.setClipToOutline(true);
        }
    }
}
