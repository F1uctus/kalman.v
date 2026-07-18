#!/usr/bin/env python3
"""Сверка вывода C-бинаря CertiRocq с JSON-данными paper/data.

Использование: check.py <вывод kalman_c_bin> <каталог paper/data>

Бинарь печатает точные дроби; JSON хранит их приближения в double.
Скрипт сравнивает значения с допуском и повторяет проверку коридора
плюс минус два сигма на точных дробях.
"""

import json
import sys
from fractions import Fraction

REL = 1e-9
ABS = 1e-12

errors = 0


def fail(msg):
    global errors
    errors += 1
    print(f"FAIL: {msg}")


def close(exact, approx):
    x = float(exact)
    return abs(x - approx) <= max(ABS, REL * max(abs(x), abs(approx)))


def check(exact, approx, what):
    if not close(exact, approx):
        fail(f"{what}: exact {exact} = {float(exact)} vs json {approx}")


def frac(tok):
    n, d = tok.split("/")
    return Fraction(int(n), int(d))


def mx(text):
    return [[frac(t) for t in row.split()] for row in text.split(";")]


def parse_sections(path):
    sections = {}
    cur = None
    for line in open(path):
        line = line.strip()
        if not line:
            continue
        if line.startswith("== "):
            cur = line.strip("= ").strip()
            sections[cur] = []
        else:
            sections[cur].append(line)
    return sections


def simrow(line):
    xt, z, xe, p = (mx(part) for part in line.split("|"))
    return xt, z, xe, p


def check_dare(lines_, data):
    iters = data["iterations"]
    if len(lines_) != len(iters):
        fail(f"dare: {len(lines_)} rows vs {len(iters)} in json")
        return
    for k, (line, it) in enumerate(zip(lines_, iters)):
        p = mx(line)
        for i in range(2):
            for j in range(2):
                check(p[i][j], it["P"][i][j], f"dare k={k} P[{i}][{j}]")


def check_sim(lines_, data):
    steps = data["steps"]
    if len(lines_) != len(steps):
        fail(f"sim: {len(lines_)} rows vs {len(steps)} in json")
        return
    for k, (line, st) in enumerate(zip(lines_, steps)):
        xt, z, xe, p = simrow(line)
        check(xt[0][0], st["x_true"][0], f"sim k={k} x_true[0]")
        check(xt[1][0], st["x_true"][1], f"sim k={k} x_true[1]")
        check(xe[0][0], st["x_est"][0], f"sim k={k} x_est[0]")
        check(xe[1][0], st["x_est"][1], f"sim k={k} x_est[1]")
        check(z[0][0], st["meas"], f"sim k={k} meas")
        check(p[0][0], st["pos_sigma"] ** 2, f"sim k={k} P00")
        e = xe[0][0] - xt[0][0]
        if e * e > 4 * p[0][0]:
            fail(f"sim k={k}: вне коридора 2 сигма")


def check_sim3(lines_, data):
    steps = data["steps"]
    if len(lines_) != len(steps):
        fail(f"sim3: {len(lines_)} rows vs {len(steps)} in json")
        return
    pos = (0, 2, 4)
    for k, (line, st) in enumerate(zip(lines_, steps)):
        xt, z, xe, p = simrow(line)
        for a, i in enumerate(pos):
            check(xt[i][0], st["true"][a], f"sim3 k={k} true[{a}]")
            check(xe[i][0], st["est"][a], f"sim3 k={k} est[{a}]")
            check(z[a][0] if len(z) == 3 else z[0][0], st["meas"][a],
                  f"sim3 k={k} meas[{a}]")
            check(p[i][i], st["sigma"][a] ** 2, f"sim3 k={k} P[{i}][{i}]")
            e = xe[i][0] - xt[i][0]
            if e * e > 4 * p[i][i]:
                fail(f"sim3 k={k}: координата {a} вне коридора 2 сигма")


def main():
    out_path, data_dir = sys.argv[1], sys.argv[2]
    sections = parse_sections(out_path)
    check_dare(sections["dare"],
               json.load(open(f"{data_dir}/dare_convergence.json")))
    check_sim(sections["sim"], json.load(open(f"{data_dir}/kalman_run.json")))
    check_sim3(sections["sim3"],
               json.load(open(f"{data_dir}/kalman_run_3d.json")))
    total = sum(len(v) for v in sections.values())
    if errors:
        print(f"{errors} расхождений")
        sys.exit(1)
    print(f"OK: {total} строк сверено с paper/data без расхождений")


if __name__ == "__main__":
    main()
