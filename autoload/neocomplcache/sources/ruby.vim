let s:source = {
      \ 'name': 'ruby',
      \ 'kind': 'ftplugin',
      \ 'filetypes': {'ruby': 1},
      \ }

function! s:source.initialize() "{{{
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
endfunction "}}}

function! neocomplcache#sources#ruby#define() "{{{
  return s:source
endfunction "}}}
