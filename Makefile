TEXDIR   = dp-text
MAIN_LUA = fi-lualatex
MAIN_PDF = fi-pdflatex
FIGDIR   = $(TEXDIR)/figures

# Cross-platform commands
ifeq ($(OS),Windows_NT)
    RM      = del /q
    RMDIR   = rmdir /s /q
    OPENER  = start ""
else
    RM      = rm -f
    RMDIR   = rm -rf
    OPENER  = xdg-open
endif

.PHONY: all lua pdf figures docx clean clean-all open open-pdf help

## Default: build with LuaLaTeX (recommended for local use)
all: figures lua

## Regenerate all PlantUML figures (requires plantuml + java)
figures:
	plantuml -tpdf $(FIGDIR)/*.puml

## Build with LuaLaTeX (better fonts, native UTF-8)
lua:
	cd $(TEXDIR) && lualatex -interaction=nonstopmode $(MAIN_LUA).tex && biber $(MAIN_LUA) && lualatex -interaction=nonstopmode $(MAIN_LUA).tex && lualatex -interaction=nonstopmode $(MAIN_LUA).tex

## Build with pdfLaTeX (matches Overleaf compiler setting)
pdf:
	cd $(TEXDIR) && pdflatex -shell-escape -interaction=nonstopmode $(MAIN_PDF).tex && biber $(MAIN_PDF) && pdflatex -shell-escape -interaction=nonstopmode $(MAIN_PDF).tex && pdflatex -shell-escape -interaction=nonstopmode $(MAIN_PDF).tex

## Open the LuaLaTeX PDF
open: $(TEXDIR)/$(MAIN_LUA).pdf
	$(OPENER) $(TEXDIR)/$(MAIN_LUA).pdf

## Open the pdfLaTeX PDF
open-pdf: $(TEXDIR)/$(MAIN_PDF).pdf
	$(OPENER) $(TEXDIR)/$(MAIN_PDF).pdf

## Remove build artifacts (keep PDFs)
clean:
	cd $(TEXDIR) && $(RM) *.aux *.bbl *.bcf *.blg *.fdb_latexmk *.fls *.lof *.log *.lot *.out *.run.xml *.synctex.gz *.toc *.xdv *.idx *.ilg *.ind *.ist 2>nul || true

## Convert thesis to DOCX (requires pandoc)
docx:
ifeq ($(OS),Windows_NT)
	@powershell -NoProfile -ExecutionPolicy Bypass -File scripts/to-docx.ps1 -TexDir $(TEXDIR) -Main $(MAIN_LUA)
else
	@mkdir -p $(TEXDIR)/_pandoc_tmp && \
	  cp $(TEXDIR)/chapters/*.tex $(TEXDIR)/_pandoc_tmp/ && \
	  for f in $(TEXDIR)/_pandoc_tmp/*.tex; do \
	    sed -i '/\\begin{tikzpicture}/,/\\end{tikzpicture}/c\\\\emph{[Figure: see PDF version]}' "$$f"; \
	  done && \
	  sed 's|chapters/|_pandoc_tmp/|g; /\\usetikzlibrary/d; /\\usepackage{tikz}/d' \
	    $(TEXDIR)/$(MAIN_LUA).tex > $(TEXDIR)/_pandoc_main.tex && \
	  cd $(TEXDIR) && pandoc _pandoc_main.tex --bibliography=thesis.bib --citeproc -o $(MAIN_LUA).docx && \
	  rm -rf _pandoc_main.tex _pandoc_tmp
endif

## Remove build artifacts AND PDFs
clean-all: clean
	cd $(TEXDIR) && $(RM) *.pdf 2>nul || true

## Count standard pages (1 page = 1,800 characters, LaTeX commands stripped)
pagecount:
ifeq ($(OS),Windows_NT)
	@powershell -NoProfile -ExecutionPolicy Bypass -File scripts/pagecount.ps1 -Dir $(TEXDIR)/chapters
else
	@total=0; for f in $(TEXDIR)/chapters/*.tex; do \
	  n=$$(sed 's/%.*//; s/\\[a-zA-Z]*{//g; s/\\[a-zA-Z]*//g; s/[{}\\]//g' "$$f" | tr -s '[:space:]' ' ' | wc -c); \
	  p=$$(echo "scale=1; $$n / 1800" | bc); \
	  total=$$((total + n)); \
	  printf "  %-25s %6d chars = %5s pages\n" "$$(basename $$f)" "$$n" "$$p"; \
	done; \
	p=$$(echo "scale=1; $$total / 1800" | bc); \
	printf "\n  TOTAL: %d chars = %s standard pages (target: 50-70)\n" "$$total" "$$p"
endif

help:
	@echo "Targets:"
	@echo "  all        Build figures + PDF with LuaLaTeX (default)"
	@echo "  figures    Regenerate PlantUML figures (PDF)"
	@echo "  lua        Build with LuaLaTeX (local, recommended)"
	@echo "  pdf        Build with pdfLaTeX  (matches Overleaf)"
	@echo "  open       Open LuaLaTeX PDF in viewer"
	@echo "  open-pdf   Open pdfLaTeX PDF in viewer"
	@echo "  pagecount  Count standard pages (1 page = 1800 chars)"
	@echo "  docx       Convert thesis to DOCX (requires pandoc)"
	@echo "  clean      Remove build artifacts (keep PDFs)"
	@echo "  clean-all  Remove build artifacts and PDFs"
