
# Compare_Images_CIEDE2000_SSIM.py  [2026.03.13]




"""

Requirements
------------

Python: 3.8+

Dependencies (pip install):

    numpy >= 1.20
    scikit-image >= 0.18
    matplotlib >= 3.5
    PyQt5 >= 5.12

Optional (for image formats other than PNG/JPG):
    Pillow >= 8.0

"""




import matplotlib
matplotlib.use("Qt5Agg")

import numpy as np
from skimage import io, color
from skimage.metrics import structural_similarity
import matplotlib.pyplot as plt
import argparse
from matplotlib import rcParams




# ------------------------------------------------------------
# CIE ΔE 2000 模式
# ------------------------------------------------------------

def run_CIEDE2000(img1, img2):

    lab1 = color.rgb2lab(img1)
    lab2 = color.rgb2lab(img2)

    delta = color.deltaE_ciede2000(lab1, lab2)

    flat = delta.flatten()

    mean_val = np.mean(flat)
    min_val = np.min(flat[flat >= 0])
    max_val = np.max(flat)

    pct_lt1 = np.mean(flat < 1) * 100
    pct_lt2 = np.mean(flat < 2) * 100
    pct_lt3 = np.mean(flat < 3) * 100

    p95 = np.percentile(flat, 95)
    p99 = np.percentile(flat, 99)

    n = len(flat)

    k5 = int(n * 0.05)
    k1 = int(n * 0.01)

    top5 = np.partition(flat, -k5)[-k5:]
    top1 = np.partition(flat, -k1)[-k1:]

    top5_mean = top5.mean()
    top1_mean = top1.mean()


    print("CIE ΔE 2000 Statistics")
    print("----------------------------")
    print(f"Mean ΔE       : {mean_val:.4f}")
    print(f"Min  ΔE       : {min_val:.4f}")
    print(f"Max  ΔE       : {max_val:.4f}")
    print(f"ΔE < 1        : {pct_lt1:.2f}%")
    print(f"ΔE < 2        : {pct_lt2:.2f}%")
    print(f"ΔE < 3        : {pct_lt3:.2f}%")
    print(f"95th Percent  : {p95:.4f}")
    print(f"99th Percent  : {p99:.4f}")
    print(f"Top 5% mean   : {top5_mean:.4f}")
    print(f"Top 1% mean   : {top1_mean:.4f}")

    stats_text = (
        f"Mean ΔE       : {mean_val:.4f}\n"
        f"Min  ΔE       : {min_val:.4f}\n"
        f"Max  ΔE       : {max_val:.4f}\n"
        f"ΔE < 1        : {pct_lt1:.2f}%\n"
        f"ΔE < 2        : {pct_lt2:.2f}%\n"
        f"ΔE < 3        : {pct_lt3:.2f}%\n"
        f"95th Percent  : {p95:.4f}\n"
        f"99th Percent  : {p99:.4f}\n"
        f"Top 5% mean   : {top5_mean:.4f}\n"
        f"Top 1% mean   : {top1_mean:.4f}"
    )


    CL = plt.get_cmap("gray_r").copy()
    CL.set_over("red")

    im = plt.imshow(delta, cmap=CL, vmin=0, vmax=p99)

    cbar = plt.colorbar(im, fraction=0.04, pad=0.04, extend="max")
    cbar.set_label("CIE ΔE 2000", rotation=270, labelpad=15)

    return stats_text




# ------------------------------------------------------------
# SSIM 模式
# ------------------------------------------------------------

def run_SSIM(img1, img2):

    score, ssim_map = structural_similarity(
        img1,
        img2,
        channel_axis=2,
        full=True
    )

    diff_map = 1 - ssim_map.mean(axis=2)

    flat = diff_map.flatten()

    mean_val = np.mean(flat)
    min_val = np.min(flat[flat >= 0])
    max_val = np.max(flat)

    pct_lt1 = np.mean(flat < 0.08) * 100
    pct_lt2 = np.mean(flat < 0.12) * 100
    pct_lt3 = np.mean(flat < 0.16) * 100

    p95 = np.percentile(flat, 95)
    p99 = np.percentile(flat, 99)

    n = len(flat)

    k5 = int(n * 0.05)
    k1 = int(n * 0.01)

    top5 = np.partition(flat, -k5)[-k5:]
    top1 = np.partition(flat, -k1)[-k1:]

    top5_mean = top5.mean()
    top1_mean = top1.mean()


    print("[1-SSIM] Statistics")
    print("----------------------------")
    print(f"Mean [1-SSIM]    : {mean_val:.4f}")
    print(f"Min  [1-SSIM]    : {min_val:.4f}")
    print(f"Max  [1-SSIM]    : {max_val:.4f}")
    print(f"[1-SSIM] < 0.08  : {pct_lt1:.2f}%")
    print(f"[1-SSIM] < 0.12  : {pct_lt2:.2f}%")
    print(f"[1-SSIM] < 0.16  : {pct_lt3:.2f}%")
    print(f"95th Percent     : {p95:.4f}")
    print(f"99th Percent     : {p99:.4f}")
    print(f"Top 5% mean      : {top5_mean:.4f}")
    print(f"Top 1% mean      : {top1_mean:.4f}")

    stats_text = (
        f"Mean [1-SSIM]      : {mean_val:.4f}\n"
        f"Min  [1-SSIM]      : {min_val:.4f}\n"
        f"Max  [1-SSIM]      : {max_val:.4f}\n"
        f"[1-SSIM] < 0.08    : {pct_lt1:.2f}%\n"
        f"[1-SSIM] < 0.12    : {pct_lt2:.2f}%\n"
        f"[1-SSIM] < 0.16    : {pct_lt3:.2f}%\n"
        f"95th Percent       : {p95:.4f}\n"
        f"99th Percent       : {p99:.4f}\n"
        f"Top 5% mean        : {top5_mean:.4f}\n"
        f"Top 1% mean        : {top1_mean:.4f}"
    )

    
    CL = plt.get_cmap("gray_r").copy()
    CL.set_over("red")

    im = plt.imshow(diff_map, cmap=CL, vmin=0, vmax=p99)

    cbar = plt.colorbar(im, fraction=0.04, pad=0.04, extend="max")
    cbar.set_label("[1-SSIM]", rotation=270, labelpad=15)

    return stats_text




# ------------------------------------------------------------
# 主程序
# ------------------------------------------------------------

def main(img_path1, img_path2, method):

    img1 = io.imread(img_path1)
    img2 = io.imread(img_path2)

    if img1.shape != img2.shape:
        raise ValueError("Images must have identical dimensions.")

    rcParams["font.family"] = "Consolas"

    fig = plt.figure()

    fig.canvas.manager.set_window_title(
        f"{method}    {img_path1}    {img_path2}"
    )


    if method == "CIEDE2000":
        stats_text = run_CIEDE2000(img1, img2)

    elif method == "SSIM":
        stats_text = run_SSIM(img1, img2)

    else:
        raise ValueError("Unknown method")


    fig.text(
        0.01,
        0.99,
        stats_text,
        fontsize=14,
        verticalalignment="top",
        horizontalalignment="left",
        bbox=dict(
            facecolor="white",
            alpha=0.8,
            edgecolor="gray"
        )
    )


    plt.tight_layout()

    figManager = fig.canvas.manager
    figManager.window.showMaximized()

    plt.show()




# ------------------------------------------------------------
# 命令行入口
# ------------------------------------------------------------

if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        description="Compare two images"
    )

    parser.add_argument("image1")
    parser.add_argument("image2")

    parser.add_argument(
        "--method",
        choices=["CIEDE2000", "SSIM"],
        default="CIEDE2000"
    )

    args = parser.parse_args()

    main(args.image1, args.image2, args.method)




