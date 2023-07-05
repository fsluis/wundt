// This file was generated automatically by the Snowball to Java compiler

package org.tartarus.snowball3.ext;
import org.tartarus.snowball3.SnowballProgram;
import org.tartarus.snowball3.Among;

/**
 * Generated class implementing code defined by a snowball script.
 */
public class German2Stemmer extends SnowballProgram {

        private Among a_0[] = {
            new Among ( "", -1, 6, "", this),
            new Among ( "ae", 0, 2, "", this),
            new Among ( "oe", 0, 3, "", this),
            new Among ( "qu", 0, 5, "", this),
            new Among ( "ue", 0, 4, "", this),
            new Among ( "\u00DF", 0, 1, "", this)
        };

        private Among a_1[] = {
            new Among ( "", -1, 6, "", this),
            new Among ( "U", 0, 2, "", this),
            new Among ( "Y", 0, 1, "", this),
            new Among ( "\u00E4", 0, 3, "", this),
            new Among ( "\u00F6", 0, 4, "", this),
            new Among ( "\u00FC", 0, 5, "", this)
        };

        private Among a_2[] = {
            new Among ( "e", -1, 1, "", this),
            new Among ( "em", -1, 1, "", this),
            new Among ( "en", -1, 1, "", this),
            new Among ( "ern", -1, 1, "", this),
            new Among ( "er", -1, 1, "", this),
            new Among ( "s", -1, 2, "", this),
            new Among ( "es", 5, 1, "", this)
        };

        private Among a_3[] = {
            new Among ( "en", -1, 1, "", this),
            new Among ( "er", -1, 1, "", this),
            new Among ( "st", -1, 2, "", this),
            new Among ( "est", 2, 1, "", this)
        };

        private Among a_4[] = {
            new Among ( "ig", -1, 1, "", this),
            new Among ( "lich", -1, 1, "", this)
        };

        private Among a_5[] = {
            new Among ( "end", -1, 1, "", this),
            new Among ( "ig", -1, 2, "", this),
            new Among ( "ung", -1, 1, "", this),
            new Among ( "lich", -1, 3, "", this),
            new Among ( "isch", -1, 2, "", this),
            new Among ( "ik", -1, 2, "", this),
            new Among ( "heit", -1, 3, "", this),
            new Among ( "keit", -1, 4, "", this)
        };

        private static final char g_v[] = {17, 65, 16, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 32, 8 };

        private static final char g_s_ending[] = {117, 30, 5 };

        private static final char g_st_ending[] = {117, 30, 4 };

        private int I_x;
        private int I_p2;
        private int I_p1;

        private void copy_from(German2Stemmer other) {
            I_x = other.I_x;
            I_p2 = other.I_p2;
            I_p1 = other.I_p1;
            super.copy_from(other);
        }

        private boolean r_prelude() {
            int among_var;
            int v_1;
            int v_2;
            int v_3;
            int v_4;
            int v_5;
            // (, line 28
            // test, line 30
            v_1 = cursor;
            // repeat, line 30
            replab0: while(true)
            {
                v_2 = cursor;
                lab1: do {
                    // goto, line 30
                    golab2: while(true)
                    {
                        v_3 = cursor;
                        lab3: do {
                            // (, line 30
                            if (!(in_grouping(g_v, 97, 252)))
                            {
                                break lab3;
                            }
                            // [, line 31
                            bra = cursor;
                            // or, line 31
                            lab4: do {
                                v_4 = cursor;
                                lab5: do {
                                    // (, line 31
                                    // literal, line 31
                                    if (!(eq_s(1, "u")))
                                    {
                                        break lab5;
                                    }
                                    // ], line 31
                                    ket = cursor;
                                    if (!(in_grouping(g_v, 97, 252)))
                                    {
                                        break lab5;
                                    }
                                    // <-, line 31
                                    slice_from("U");
                                    break lab4;
                                } while (false);
                                cursor = v_4;
                                // (, line 32
                                // literal, line 32
                                if (!(eq_s(1, "y")))
                                {
                                    break lab3;
                                }
                                // ], line 32
                                ket = cursor;
                                if (!(in_grouping(g_v, 97, 252)))
                                {
                                    break lab3;
                                }
                                // <-, line 32
                                slice_from("Y");
                            } while (false);
                            cursor = v_3;
                            break golab2;
                        } while (false);
                        cursor = v_3;
                        if (cursor >= limit)
                        {
                            break lab1;
                        }
                        cursor++;
                    }
                    continue replab0;
                } while (false);
                cursor = v_2;
                break replab0;
            }
            cursor = v_1;
            // repeat, line 35
            replab6: while(true)
            {
                v_5 = cursor;
                lab7: do {
                    // (, line 35
                    // [, line 36
                    bra = cursor;
                    // substring, line 36
                    among_var = find_among(a_0, 6);
                    if (among_var == 0)
                    {
                        break lab7;
                    }
                    // ], line 36
                    ket = cursor;
                    switch(among_var) {
                        case 0:
                            break lab7;
                        case 1:
                            // (, line 37
                            // <-, line 37
                            slice_from("ss");
                            break;
                        case 2:
                            // (, line 38
                            // <-, line 38
                            slice_from("\u00E4");
                            break;
                        case 3:
                            // (, line 39
                            // <-, line 39
                            slice_from("\u00F6");
                            break;
                        case 4:
                            // (, line 40
                            // <-, line 40
                            slice_from("\u00FC");
                            break;
                        case 5:
                            // (, line 41
                            // hop, line 41
                            {
                                int c = cursor + 2;
                                if (0 > c || c > limit)
                                {
                                    break lab7;
                                }
                                cursor = c;
                            }
                            break;
                        case 6:
                            // (, line 42
                            // next, line 42
                            if (cursor >= limit)
                            {
                                break lab7;
                            }
                            cursor++;
                            break;
                    }
                    continue replab6;
                } while (false);
                cursor = v_5;
                break replab6;
            }
            return true;
        }

        private boolean r_mark_regions() {
            int v_1;
            // (, line 48
            I_p1 = limit;
            I_p2 = limit;
            // test, line 53
            v_1 = cursor;
            // (, line 53
            // hop, line 53
            {
                int c = cursor + 3;
                if (0 > c || c > limit)
                {
                    return false;
                }
                cursor = c;
            }
            // setmark x, line 53
            I_x = cursor;
            cursor = v_1;
            // gopast, line 55
            golab0: while(true)
            {
                lab1: do {
                    if (!(in_grouping(g_v, 97, 252)))
                    {
                        break lab1;
                    }
                    break golab0;
                } while (false);
                if (cursor >= limit)
                {
                    return false;
                }
                cursor++;
            }
            // gopast, line 55
            golab2: while(true)
            {
                lab3: do {
                    if (!(out_grouping(g_v, 97, 252)))
                    {
                        break lab3;
                    }
                    break golab2;
                } while (false);
                if (cursor >= limit)
                {
                    return false;
                }
                cursor++;
            }
            // setmark p1, line 55
            I_p1 = cursor;
            // try, line 56
            lab4: do {
                // (, line 56
                if (!(I_p1 < I_x))
                {
                    break lab4;
                }
                I_p1 = I_x;
            } while (false);
            // gopast, line 57
            golab5: while(true)
            {
                lab6: do {
                    if (!(in_grouping(g_v, 97, 252)))
                    {
                        break lab6;
                    }
                    break golab5;
                } while (false);
                if (cursor >= limit)
                {
                    return false;
                }
                cursor++;
            }
            // gopast, line 57
            golab7: while(true)
            {
                lab8: do {
                    if (!(out_grouping(g_v, 97, 252)))
                    {
                        break lab8;
                    }
                    break golab7;
                } while (false);
                if (cursor >= limit)
                {
                    return false;
                }
                cursor++;
            }
            // setmark p2, line 57
            I_p2 = cursor;
            return true;
        }

        private boolean r_postlude() {
            int among_var;
            int v_1;
            // repeat, line 61
            replab0: while(true)
            {
                v_1 = cursor;
                lab1: do {
                    // (, line 61
                    // [, line 63
                    bra = cursor;
                    // substring, line 63
                    among_var = find_among(a_1, 6);
                    if (among_var == 0)
                    {
                        break lab1;
                    }
                    // ], line 63
                    ket = cursor;
                    switch(among_var) {
                        case 0:
                            break lab1;
                        case 1:
                            // (, line 64
                            // <-, line 64
                            slice_from("y");
                            break;
                        case 2:
                            // (, line 65
                            // <-, line 65
                            slice_from("u");
                            break;
                        case 3:
                            // (, line 66
                            // <-, line 66
                            slice_from("a");
                            break;
                        case 4:
                            // (, line 67
                            // <-, line 67
                            slice_from("o");
                            break;
                        case 5:
                            // (, line 68
                            // <-, line 68
                            slice_from("u");
                            break;
                        case 6:
                            // (, line 69
                            // next, line 69
                            if (cursor >= limit)
                            {
                                break lab1;
                            }
                            cursor++;
                            break;
                    }
                    continue replab0;
                } while (false);
                cursor = v_1;
                break replab0;
            }
            return true;
        }

        private boolean r_R1() {
            if (!(I_p1 <= cursor))
            {
                return false;
            }
            return true;
        }

        private boolean r_R2() {
            if (!(I_p2 <= cursor))
            {
                return false;
            }
            return true;
        }

        private boolean r_standard_suffix() {
            int among_var;
            int v_1;
            int v_2;
            int v_3;
            int v_4;
            int v_5;
            int v_6;
            int v_7;
            int v_8;
            int v_9;
            // (, line 79
            // do, line 80
            v_1 = limit - cursor;
            lab0: do {
                // (, line 80
                // [, line 81
                ket = cursor;
                // substring, line 81
                among_var = find_among_b(a_2, 7);
                if (among_var == 0)
                {
                    break lab0;
                }
                // ], line 81
                bra = cursor;
                // call R1, line 81
                if (!r_R1())
                {
                    break lab0;
                }
                switch(among_var) {
                    case 0:
                        break lab0;
                    case 1:
                        // (, line 83
                        // delete, line 83
                        slice_del();
                        break;
                    case 2:
                        // (, line 86
                        if (!(in_grouping_b(g_s_ending, 98, 116)))
                        {
                            break lab0;
                        }
                        // delete, line 86
                        slice_del();
                        break;
                }
            } while (false);
            cursor = limit - v_1;
            // do, line 90
            v_2 = limit - cursor;
            lab1: do {
                // (, line 90
                // [, line 91
                ket = cursor;
                // substring, line 91
                among_var = find_among_b(a_3, 4);
                if (among_var == 0)
                {
                    break lab1;
                }
                // ], line 91
                bra = cursor;
                // call R1, line 91
                if (!r_R1())
                {
                    break lab1;
                }
                switch(among_var) {
                    case 0:
                        break lab1;
                    case 1:
                        // (, line 93
                        // delete, line 93
                        slice_del();
                        break;
                    case 2:
                        // (, line 96
                        if (!(in_grouping_b(g_st_ending, 98, 116)))
                        {
                            break lab1;
                        }
                        // hop, line 96
                        {
                            int c = cursor - 3;
                            if (limit_backward > c || c > limit)
                            {
                                break lab1;
                            }
                            cursor = c;
                        }
                        // delete, line 96
                        slice_del();
                        break;
                }
            } while (false);
            cursor = limit - v_2;
            // do, line 100
            v_3 = limit - cursor;
            lab2: do {
                // (, line 100
                // [, line 101
                ket = cursor;
                // substring, line 101
                among_var = find_among_b(a_5, 8);
                if (among_var == 0)
                {
                    break lab2;
                }
                // ], line 101
                bra = cursor;
                // call R2, line 101
                if (!r_R2())
                {
                    break lab2;
                }
                switch(among_var) {
                    case 0:
                        break lab2;
                    case 1:
                        // (, line 103
                        // delete, line 103
                        slice_del();
                        // try, line 104
                        v_4 = limit - cursor;
                        lab3: do {
                            // (, line 104
                            // [, line 104
                            ket = cursor;
                            // literal, line 104
                            if (!(eq_s_b(2, "ig")))
                            {
                                cursor = limit - v_4;
                                break lab3;
                            }
                            // ], line 104
                            bra = cursor;
                            // not, line 104
                            {
                                v_5 = limit - cursor;
                                lab4: do {
                                    // literal, line 104
                                    if (!(eq_s_b(1, "e")))
                                    {
                                        break lab4;
                                    }
                                    cursor = limit - v_4;
                                    break lab3;
                                } while (false);
                                cursor = limit - v_5;
                            }
                            // call R2, line 104
                            if (!r_R2())
                            {
                                cursor = limit - v_4;
                                break lab3;
                            }
                            // delete, line 104
                            slice_del();
                        } while (false);
                        break;
                    case 2:
                        // (, line 107
                        // not, line 107
                        {
                            v_6 = limit - cursor;
                            lab5: do {
                                // literal, line 107
                                if (!(eq_s_b(1, "e")))
                                {
                                    break lab5;
                                }
                                break lab2;
                            } while (false);
                            cursor = limit - v_6;
                        }
                        // delete, line 107
                        slice_del();
                        break;
                    case 3:
                        // (, line 110
                        // delete, line 110
                        slice_del();
                        // try, line 111
                        v_7 = limit - cursor;
                        lab6: do {
                            // (, line 111
                            // [, line 112
                            ket = cursor;
                            // or, line 112
                            lab7: do {
                                v_8 = limit - cursor;
                                lab8: do {
                                    // literal, line 112
                                    if (!(eq_s_b(2, "er")))
                                    {
                                        break lab8;
                                    }
                                    break lab7;
                                } while (false);
                                cursor = limit - v_8;
                                // literal, line 112
                                if (!(eq_s_b(2, "en")))
                                {
                                    cursor = limit - v_7;
                                    break lab6;
                                }
                            } while (false);
                            // ], line 112
                            bra = cursor;
                            // call R1, line 112
                            if (!r_R1())
                            {
                                cursor = limit - v_7;
                                break lab6;
                            }
                            // delete, line 112
                            slice_del();
                        } while (false);
                        break;
                    case 4:
                        // (, line 116
                        // delete, line 116
                        slice_del();
                        // try, line 117
                        v_9 = limit - cursor;
                        lab9: do {
                            // (, line 117
                            // [, line 118
                            ket = cursor;
                            // substring, line 118
                            among_var = find_among_b(a_4, 2);
                            if (among_var == 0)
                            {
                                cursor = limit - v_9;
                                break lab9;
                            }
                            // ], line 118
                            bra = cursor;
                            // call R2, line 118
                            if (!r_R2())
                            {
                                cursor = limit - v_9;
                                break lab9;
                            }
                            switch(among_var) {
                                case 0:
                                    cursor = limit - v_9;
                                    break lab9;
                                case 1:
                                    // (, line 120
                                    // delete, line 120
                                    slice_del();
                                    break;
                            }
                        } while (false);
                        break;
                }
            } while (false);
            cursor = limit - v_3;
            return true;
        }

        public boolean stem() {
            int v_1;
            int v_2;
            int v_3;
            int v_4;
            // (, line 130
            // do, line 131
            v_1 = cursor;
            lab0: do {
                // call prelude, line 131
                if (!r_prelude())
                {
                    break lab0;
                }
            } while (false);
            cursor = v_1;
            // do, line 132
            v_2 = cursor;
            lab1: do {
                // call mark_regions, line 132
                if (!r_mark_regions())
                {
                    break lab1;
                }
            } while (false);
            cursor = v_2;
            // backwards, line 133
            limit_backward = cursor; cursor = limit;
            // do, line 134
            v_3 = limit - cursor;
            lab2: do {
                // call standard_suffix, line 134
                if (!r_standard_suffix())
                {
                    break lab2;
                }
            } while (false);
            cursor = limit - v_3;
            cursor = limit_backward;            // do, line 135
            v_4 = cursor;
            lab3: do {
                // call postlude, line 135
                if (!r_postlude())
                {
                    break lab3;
                }
            } while (false);
            cursor = v_4;
            return true;
        }

}

