use proconio::{fastout, input, marker::Chars};

#[fastout]
fn main() {
    input! {
        n: usize,
        mut s: Chars,
    }
    let mut ans = 0;
    let happy = ['H', 'A', 'P', 'P', 'Y'];
    for i in 4..(n - 5) {
        if s[(i - 4)..=i] == happy {
            for j in 0..=i {
                s[i - 4 + j] = 'Z';
                ans += 1;
                break;
            }
        }
    }

    for i in (n - 5)..n {
        if s[i] != happy[i + 5 - n] {
            ans += 1;
        }
    }

    println!("{}", ans);
}
