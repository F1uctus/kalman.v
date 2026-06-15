// Copyright (C) 2026 Ilya I. Nikitin <ilya.i.nikitin@proton.me>
// SPDX-License-Identifier: GPL-3.0-or-later

#import "markup-shorthands.typ" as markup-shorthands
#import "markup-shorthands.typ": *

#show "†": math.attach("", tr: sym.ast)
#show math.frac: f => $(#f.num) slash (#f.denom)$

#let markup-eval-scope = dictionary(markup-shorthands)
