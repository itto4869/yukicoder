use proconio::{fastout, input};

#[fastout]
fn main() {
    input! {
        n: usize,
        s: usize,
        mut a: [usize; n],
    }

    a.sort_unstable();
    a.reverse();
    let mut ok = a.iter().sum::<usize>();
    let mut ng = 0;
    while (ok - ng) > 1 {
        let mid = (ok + ng) / 2;

        let mut x = 0;
        for i in (0..n).step_by(mid) {
            if a[i] <= mid {
                break;
            }

            x += a[i];
        }

        if x < s {
            ok = mid;
        } else {
            ng = mid;
        }
    }

    println!("{}", ok);
}
