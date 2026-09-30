need_string_match(in_site({'domain_changer', 'url'}), '^https?://')
need_string_array_match(in_site({'domain_changer', 'pubkeys'}), '^%x+$')
need_number(in_site({'domain_changer', 'good_signatures'}), false)
