let s:source = {
      \ 'name': 'ruby',
      \ 'kind': 'ftplugin',
      \ 'filetypes': {'ruby': 1},
      \ }

function! s:source.initialize() "{{{
  return
  let s:browse_cache = {}
  let s:modules_cache = {}
  call s:ghc_mod_caching_list()
  call s:ghc_mod_caching_lang()
  call s:ghc_mod_caching_browse('Prelude')

  augroup neocomplcache
    autocmd FileType haskell call s:caching_modules()
    autocmd InsertLeave * if has_key(s:modules_cache, bufnr('%')) | call s:caching_modules() | endif
  augroup END

  command! -nargs=0 NeoComplCacheCachingGhcImports call s:caching_modules()
endfunction "}}}

function! s:source.finalize() "{{{
  return
  delcommand NeoComplCacheCachingGhcImports
endfunction "}}}

function! s:source.get_keyword_pos(cur_text)  "{{{
  if neocomplcache#within_comment()
    return -1
  endif

  if filereadable(expand('%')) && a:cur_text =~# "require_relative '"
    return matchend("require_relative '", a:cur_text)
  endif
  return -1
  if 1
    if a:cur_text =~# '(.*,'
      return s:last_matchend(a:cur_text, ',\s*')
    endif
    let parp = matchend(a:cur_text, '(')
    return parp > 0 ? parp :
          \ matchend(a:cur_text, '^import\s\+\(qualified\s\+\)\?')
  else
    " let l:pattern = neocomplcache#get_keyword_pattern_end('haskell')
    let l:pattern = "\\%([[:alpha:]_'][[:alnum:]_'.]*\\m\\)$"
    let [l:cur_keyword_pos, l:cur_keyword_str] = neocomplcache#match_word(a:cur_text, l:pattern)
    return l:cur_keyword_pos
  endif
endfunction "}}}

function! s:source.get_complete_words(cur_keyword_pos, cur_keyword_str) "{{{
  "let l:syn = neocomplcache#get_syn_name(0)
  let l:files = split(glob(expand('%:h') . '/*.rb'), "\n")
  let l:files = filter(l:files, "v:val != expand('%')")
  let l:rubies = map(l:files, "fnamemodify(v:val, ':t:r')")
  return map(l:rubies, "{'word': v:val, 'menu': '[ruby] require_relative'}")
  let l:list = []
  let l:line = getline('.')

  if l:line =~# '^import\>.*('
    let l:mod = matchlist(l:line, 'import\s\+\(qualified\s\+\)\?\([^ (]\+\)')[2]
    for l:func in s:ghc_mod_browse(l:mod)
      call add(l:list, { 'word': l:func, 'menu': printf('[ghc] %s.%s', l:mod, l:func) })
    endfor
    return neocomplcache#keyword_filter(l:list, a:cur_keyword_str)
  endif

  if neocomplcache#is_auto_complete() &&
        \ len(a:cur_keyword_str) < g:neocomplcache_auto_completion_start_length
    return []
  endif

  let l:syn = neocomplcache#get_syn_name(0)
  if l:line =~# '^import\s'
    for l:mod in s:list_cache
      call add(l:list, { 'word': l:mod, 'menu': '[ghc] ' . l:mod })
    endfor
  elseif l:syn =~# 'Pragma'
    if match(l:line, '{-#\s\+\zs\w*') == a:cur_keyword_pos
      for l:p in s:pragmas
        call add(l:list, { 'word': l:p, 'menu': '[ghc] ' . l:p })
      endfor
    elseif l:line =~# 'LANGUAGE'
      for l:lang in s:lang_cache
        call add(l:list, { 'word': l:lang, 'menu': '[ghc] ' . l:lang })
        call add(l:list, { 'word': 'No' . l:lang, 'menu': '[ghc] No' . l:lang })
      endfor
    endif
  elseif a:cur_keyword_str =~# '\.'
    " qualified
    let l:idx = s:last_matchend(a:cur_keyword_str, '\.')
    let l:qual = a:cur_keyword_str[0 : l:idx-2]
    let l:name = a:cur_keyword_str[l:idx :]

    for [l:mod, l:opts] in items(s:get_modules())
      if l:mod == l:qual || (has_key(l:opts, 'as') && l:opts.as == l:qual)
        let l:symbols = s:ghc_mod_browse(l:mod)
        for l:sym in l:symbols
          call add(l:list, { 'word': printf('%s.%s', l:qual, l:sym), 'menu': printf('[ghc] %s.%s', l:mod, l:sym) })
        endfor
      endif
    endfor
  else
    for [l:mod, l:opts] in items(s:get_modules())
      if !l:opts.qualified || l:opts.export
        let l:symbols = s:ghc_mod_browse(l:mod)
        for l:sym in l:symbols
          call add(l:list, { 'word': l:sym, 'menu': printf('[ghc] %s.%s', l:mod, l:sym) })
        endfor
      endif
    endfor
  endif

  return neocomplcache#keyword_filter(l:list, a:cur_keyword_str)
endfunction "}}}

function! neocomplcache#sources#ruby#define() "{{{
  return s:source
endfunction "}}}
