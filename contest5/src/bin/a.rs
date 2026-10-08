use proconio::{fastout, input};

#[fastout]
fn main() {
    input! {
        l: usize,
        n: usize,
        mut w: [usize; n],
    }
    w.sort_unstable();
    let mut cnt = 0;
    let mut ans = 0;
    for wi in w {
        cnt += wi;
        if cnt > l {
            break;
        } else {
            ans += 1;
        }
    }

    println!("{}", ans);
}
